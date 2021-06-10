pipeline{
    agent any
    stages{
        stage('build'){
            agent {
    
               
                }
            steps{
                sh label: '', script: 'cd /home/codefiles'

                git changelog: false, credentialsId: '<git_credential>', poll: false, url: '<git url for app>'
                sh label: '', script: 'ls -a'
                sh label: '', script: 'mvn package'
            }
            post {
                success {
                        archiveArtifacts artifacts: 'target/*.war', fingerprint: true
                        }
                    failure {                        
                        mail to: '<recipient>', subject: "Build Failed: ${currentBuild.fullDisplayName}",body: "This is the build ${env.BUILD_URL}"
                        cleanWs()
                        } 
                }    
            
        }


        stage('test'){
            
            steps{
                sh label:'',script:"docker container run -itd --name webdocker -p 80:8094 awsacdev/ubuntu_tomcat:1.0"
                sh label:'',script:"docker cp ${env.JENKINS_HOME}/jobs/${currentBuild.projectName}/builds/${currentBuild.number}/archive/target/. webdocker:/servers/tomcat8/webapps"
                }
            post {
                success{
                    echo 'success'
                    mail to: '<recipient>',subject: "Deployed to Test: ${currentBuild.fullDisplayName}",body: "This is the build ${env.BUILD_URL}\n Test with this URL:${env.JENKINS_URL}Devops_maven_1-1.0.0/  \n\n Abort URL: ${env.BUILD_URL}stop"
                    }
                failure{
                    mail to: '<recipient>', subject: "Failed to deploy to test: ${currentBuild.fullDisplayName}",body: "This is the build ${env.BUILD_URL}"
                    sh label:'',script:"docker container rm -f webdocker"
                    cleanWs()
                }
            }

        }

        stage('Approval Step'){
            steps{
                
                //----------------send an approval prompt-------------
                script {
                   env.APPROVED_DEPLOY = input message: 'User input required',
                   parameters: [choice(name: 'Deploy?', choices: 'no\nyes', description: 'Choose "yes" if you want to deploy this build')]
                       }
                //-----------------end approval prompt------------
            }
        }

        stage('deploy'){
           
            when {
                environment name:'APPROVED_DEPLOY', value: 'yes'
            }

            steps{               
                sh label:'',script:"docker container rm -f webdocker"
                echo 'deploy stage'
                git changelog: false, credentialsId: '<GIT credential>', poll: false, url: '<CHEF GIT URL>'
                sh label: '', script: "ls -a"
               
                //-----copy war file--
                sh label:'',script:"cp -r ${env.JENKINS_HOME}/jobs/${currentBuild.projectName}/builds/${currentBuild.number}/archive/target/. ${env.WORKSPACE}/cookbooks/prepare_env/files/default/warfile"
                //--------end copy war file---

                //------------create .chef folder----
                sh label:'',script:'mkdir -p .chef'
                //-----------end create .chef folder---- 

                //---copy knife folder
                sh label:'',script:"aws s3 cp s3://<knife_file> ${env.WORKSPACE}/.chef --recursive --profile adminprof"
                //---end copy knife folder
                
                //--------launch instance--

                sh label:'',script:"aws ec2 run-instances --image-id ami-026c8acd92718196b --instance-type t2.micro --key-name <KEY_NAME> --security-group-ids <SG_ID> --subnet-id <SUBNET_ID> --count 1 --associate-public-ip-address --region us-east-1 --tag-specifications 'ResourceType=instance,Tags=[{Key=Name,Value=WebServer}]' --profile jenkinsprof"
                //---------end launch instance--

                //waiting for the instance to be launched
                sleep 30
                script {
                    env.EC2DNS = sh(label:'',script:"aws ec2 describe-instances --filters 'Name=tag:Name,Values=WebServer' 'Name=instance-state-name,Values=running' --query 'Reservations[].Instances[].PublicDnsName' --profile jenkinsprof",returnStdout: true).trim()
                        }
                echo "${env.EC2DNS}"

                //-----get instance id
                script {
                    env.EC2INST = sh(label:'',script:"aws ec2 describe-instances --filters 'Name=tag:Name,Values=WebServer' --query 'Reservations[].Instances[].InstanceId' --profile jenkinsprof",returnStdout: true).trim()
                        }
                echo "${env.EC2INST}"
                
                //------end get instance id
                
                //upload war file to cookbook
                sh label:'',script:'knife upload cookbooks --force --no-freeze'
                //---end upload war file to cookbook

                //-----copy key pair
                sh label:'',script:"aws s3 cp s3://<key_file> ${env.WORKSPACE} --recursive --profile adminprof"
                //------end copy pair
                
                //---bootstrap node
                sh label:'',script:"knife bootstrap ${env.EC2DNS} --ssh-user <USER> --sudo --yes --ssh-identity-file <KEY_FILE> --node-name prodnode --run-list 'role[prodserver]'"
                //----end bootstrap node


            }
            post{
                aborted{
                    sh label:'',script:"docker container rm -f webdocker"
                }
                failure{
                    mail to: '<recipient>',subject: "Failed PROD deployment: ${currentBuild.fullDisplayName}",body: "This is the build ${env.BUILD_URL}"
                    //terminate the ec2
                    sh label:'',script:"aws ec2 terminate-instances --instance-ids ${env.EC2INST} --profile jenkinsprof"
                    cleanWS()
                }
                success{
                    mail to: '<recipient>',subject: "Deployment to PROD succeeded: ${currentBuild.fullDisplayName}",body: "This is the build ${env.BUILD_URL}. The application is live at ${env.EC2DNS}/Devops_maven_1-1.0.0/"
                    cleanWs()
                }
            }
        }

        stage('abortdeploy'){
            when{
                environment name:'APPROVED_DEPLOY',value:'no'
            }
            steps{
                sh label:'',script:"docker container rm -f webdocker"
                mail to:'<recipient>',subject:'Deployment Aborted',body:"The deployment has been aborted. Here are the details: Project Name: ${currentBuild.projectName} Build #: ${currentBuild.number}"
                }
            post {
                always{
                    cleanWS()
                }
            }
        }
    }
}
