# <strong>An example Jenkins flow using Declarative Pipeline syntax and implemented in AWS</strong>  

In this post I will go through a simple Jenkinsfile which defines a generic development to deployment flow for a Java web app using JSP. I will be explaining each phase of the flow along with the code snippets. Below are the components used to complete the flow:  
 * Jenkins  
 * The Jenkinsfile is written in Declarative pipeline syntax  
 * Docker  
 * Java for the sample web app to be deployed  
 * Maven to compile and build the artifact  

 The full codebase can be found on my GitHub Repository:  
 https://github.com/amlana21/jenkinssampleflow  

 The supporting Docker images can be found on my Docker Hub page:  
 https://hub.docker.com/u/awsacdev  



I have used a sample web app to demonstrate the flow but this can be customized to test and deploy other platform apps too(like NodeJS or simple webpage).  
Below image gives a high level view of the process which is built in the Jenkinsfile. We will go thorugh each phase in detail.  

 ![Dev Flow](/images/flow.png)  

## <strong>Few lines about the sample App</strong>  
The sample app which I used in this flow is a straight forward Java Web App. The UI is a JSP page with the logic built in Java. This a view of the App. I havent made the app very complex beause target of this is the Jenkins process. The app consists of a text box. When a text is entered in the textbox, and the form is submitted, the text entered is shown in the read-only textbox below.  

![Dev Flow](/images/app.png)   

## <strong>Pre-Requisites to run the Pipeline</strong>  
Before this pipeline can be executed, below steps and setups are required to be done for the Jenkins flow to run properly:  
 * An AWS account. The free tier should be enough  
 * Create a CHEF Manage account
    * Create a new Org. Create a new project and generate the knife file. Download the knife file and the CHEF manage Key file
    * Upload the files to two S3 buckets in the AWS account
 * Configure AWS CLI on the Jenkins master and create two profiles:  
    * adminprof: To perform admin functions on the AWS account  
    * jenkinsprof: To launch the instances  
 * Make sure CHEF/CHEF Workstation is installed in Jenkins master  
 * Two GIT repositiories needed which are used here(files in the supporting_files folder):  
    * Create a GIT repo and load the <em>webappfordevops</em> contents to it. This is the sample app  
    * Create a GIT and load the <em>devopsprojectchef</em> contents to it. This is the CHEF repo  
 * Below packages need to be installed in Jenkins master:  
    * GIT  
    * Maven  
    * Docker  
 * Credentials need to be setup in Jenkins for the GIT repositories  
 * Certain parameters in the Jenkinsfile is just a placeholder. Those need to be changed based on the details from actual       environments.

## <strong>Walkthrough of each Phase involved in the flow</strong>  

In following sections I will be describing each phase in detail and describing how each phase works. This is the pipeline view in the modern Blue Ocean UI:  

![Dev Flow](/images/flow_look.png)  

### <strong>Build Phase</strong>  
This phase performs the compile and building of the code to generate the WAR file. This phase compiles the code and checks if the change introduced works with the existing code. If the build fails, that means the new change which triggered the flow, breaks the code and should be rolled back. This phase is the CI(Continuous Integration) part of the process. Below is the code snippet for this phase: 


 ```groovy
 stage('build'){
            agent {
    
                dockerfile {
                    filename 'Dockerfile'
                    dir 'build'
                    args '-v $PWD:/home/codefiles'
                            }
                }
            steps{
                sh label: '', script: 'cd /home/codefiles'

                git changelog: false, credentialsId: <git credential>, poll: false, url: <git url for the code to be deployed>
                sh label: '', script: 'ls -a'
                sh label: '', script: 'mvn package'
            }
            post {
                success {
                        archiveArtifacts artifacts: 'target/*.war', fingerprint: true
                        }
                    failure {                        
                        mail to: <email recipient>, subject: "Build Failed: ${currentBuild.fullDisplayName}",body: "This is the build ${env.BUILD_URL}"
                        cleanWs()
                        } 
                }    
            
        }  
```

The build is performed in a temporary docker container which is launched just for the build phase. The docker container is laucnhed from the image which is built from the Docker file in the 'build' folder. This specified in the agent section. Below are the build steps which are performed:  
 * Checkout the app code from GIT repository  
 * Run the Maven command to compile and generate the WAR file  
 * If it compiles successfully, then the WAR file is archived as an artifact in the workspace  
 * If the build fails, then it fails the pipeline and sends out an email alerting concerned team regarding the failure  

### <strong>Test Phase</strong>  
Once the build is done, this phase will handle the testing of the web app. This is a manual testing step and will be performed by a manual intervention. Below is the code snippet for this phase:  

```groovy
 stage('test'){
            
            steps{
                sh label:'',script:"docker container run -itd --name webdocker -p 80:8094 awsacdev/ubuntu_tomcat:1.0"
                sh label:'',script:"docker cp ${env.JENKINS_HOME}/jobs/${currentBuild.projectName}/builds/${currentBuild.number}/archive/target/. webdocker:/servers/tomcat8/webapps"
                }
            post {
                success{
                    echo 'success'
                    mail to: <email recipient>,subject: "Deployed to Test: ${currentBuild.fullDisplayName}",body: "This is the build ${env.BUILD_URL}\n Test with this URL:${env.JENKINS_URL}Devops_maven_1-1.0.0/  \n\n Abort URL: ${env.BUILD_URL}stop"
                    }
                failure{
                    mail to: <email recipient>, subject: "Failed to deploy to test: ${currentBuild.fullDisplayName}",body: "This is the build ${env.BUILD_URL}"
                    sh label:'',script:"docker container rm -f webdocker"
                    cleanWs()
                }
            }

        }
```  

For the test, a Docker container is launched with a customized image for Tomcat.The image is available on my account in DockerHub. The image name is: <em>awsacdev/ubuntu_tomcat</em>.  
Details of the image can be found here:  
https://cloud.docker.com/u/awsacdev/repository/docker/awsacdev/ubuntu_tomcat  
Below steps are performed in this phase:  
 * The Docker container is launched from the custom image  
 * The WAR file(archived artifact) is copied to the Tomcat Webapp location inside the container  
 * The exposed container port is mapped to the host port of 80  
 * Once the WAR file is copied, the webapp URL is emailed out to the team or person who will test the App  
 * If the deploy to this staging container fails, the pipeline is failed and email is sent out to concerned team alerting about the failure  


### <strong>Approval Phase</strong>  
This is not really a separate phase but is more of an approval step to approve the deployment of the code to Production or reject the build to stop the pipeline execution. It is built as a phase to keep the email approval part separate and properly visible. Below is the code snippet for this phase:  
 
```groovy
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
```  

Once the staging container is launched in the Testing phase and email is received by the person who is testing and approving, he/she can test the app from the link in the email. Once decided, the person can login to Jenkins and Approve or Reject on the prompt which pops up on the pipeline. This step pauses the pipeline execution and waits for the user input to allow proceeding with the flow or abort the flow.  
I used a script step to embed a scripted pipeline component in the declarative pipeline. If the approver selects proceed, this will set an environment variable which will be used in the next stage to decide on the Production deployment. The approver is presented with a prompy like this when they login to Jenkins using the link sent over the email:  

![Dev Flow](/images/prompt.png)   

<strong>Note: </strong> Please do not use input step this way in Production. In actual prodction flow the tester and Production deployment approver will be separate persons and the pipeline has to be customized accordingly.  


 ### <strong>Deployment Phase</strong> 
 This is the final phase where the app is deployed to Production instance.This step runs based on the output from previous step. Based on the environment variable set in the previous step, this step runs or is skipped. This step launches a new instance and deploys the WAR file to a Docker container in the Production instance. Below is the code snippet for this phase.. I am not including the whole phase since its a big section. Please check the Github Repository for full code:  



```groovy
stage('deploy'){
           
            when {
                environment name:'APPROVED_DEPLOY', value: 'yes'
            }

            steps{               
                sh label:'',script:"docker container rm -f webdocker"
                echo 'deploy stage'
                git changelog: false, credentialsId: '<GIT credential>', poll: false, url: '<CHEF GIT URL>'
                sh label: '', script: "ls -a"
               
                ----------------------------------------------------------------------------------------
                ----------------------------------more code lines---------------------------------------
                ----------------------------------------------------------------------------------------
                
                //---bootstrap node
                sh label:'',script:"knife bootstrap ${env.EC2DNS} --ssh-user <USER> --sudo --yes --ssh-identity-file <KEY_FILE> --node-name prodnode --run-list 'role[prodserver]'"
                //----end bootstrap node


            }
            post{
                ----------------------------------------------------------------------------------------
                ----------------------------------more code lines---------------------------------------
                ----------------------------------------------------------------------------------------
                success{
                    mail to: '<recipient>',subject: "Deployment to PROD succeeded: ${currentBuild.fullDisplayName}",body: "This is the build ${env.BUILD_URL}. The application is live at ${env.EC2DNS}/Devops_maven_1-1.0.0/"
                    cleanWs()
                }
            }
        }
```  

Below are high level steps performed in this phase:  
 * The staging container is removed  
 * The CHEF cookbook is checked out from the CHEF Repository. This will be used to bootstrap the instance for deployment  
 * The Knife file required by the CHEF recipe is downloaded from an AWS S3 location  
 * The Key file required by the CHEF recipe is also downloaded from an AWS S3 location
 * The WAR file is uploaded to the CHEF server  
 * A new instance is launched using AWS CLI and the launched Instance ID,DNS are stored in environment variables  
 * The launched instance is bootstrapped using the CHEF role defined in the repo.  
 * If these steps succeed, an email gets sent out notifying the team about Production deployment success  
 * If this fails, the launched instance is terminated and necessary email is sent out  

 There is a final stage included to handle steps when the approver rejects in the approval step. This step performs the necessary cleanups and ends the pipeline. Below is the code snippet for this phase    

 ```groovy
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
```  

<strong>Note: </strong>This is type of deployment is good for learning and testing but for actual Production deployment, it will be more complex. Please do not use this method in actual Production. There will be other strategies like Blue/Green deployment, need to be implemented for good Production deployment.  

## <strong>Different components used in the Pipeline</strong>  
Below is an overview of the Dockerfile, Docker images and the CHEF Repo used in the pipeline.  

### <strong>Build Dockerfile</strong>  
The docker file which is used to build the image for the build container, consists of the following packages:  
 * Python  
 * GIT  
 * Maven  
 * NodeJS  
There is also a folder which is the default location for any code files need to be built<em>/home/codefiles</em>. This location is mounted as volume when containers are launched.  

### <strong>Tomcat Docker Image</strong>  
More details for the image can be founcd on my Docker Hub page:  
https://cloud.docker.com/u/awsacdev/repository/docker/awsacdev/ubuntu_tomcat  

### <strong>CHEF Repo and Cookbook</strong> 
Below are the high level descriptions of the tasks performed by the CHEF role. It contains a role which applies the necessary recipes to the target. Steps:  
 * Install Docker  
 * Launch the Tomcat container  
 * Copies the WAR file from the cookbook files folder to the Webapps folder in container


## <strong>Conclusion</strong>  
This Jenkins pipeline will help you with some basics on how to write a Jenkinsfile and how to run a Development to Deployment process. To use this pipeline in a Production grade flow, below are some suggestions which can be implemented:  
 * Use Automated testing step instead of manual testing  
 * Use Blue/Green deployment strategy and perform deployment using a second instance for testing and final deploy. Include a step to   terminate the Blue instance(old instance not containing the updated app)  
 * Implement a better approval process involving approval over email(need more advanced scripting)  

This pipeline can be customized to handle other deployment processes too like NodeJS app, Flask App etc. The phases and steps need to be changed accordingly in the Jenkinsfile. Let me know in comments or email me and I can write a post about a deployment pipeline for other apps.

Please let me know if any questions reagrding the flow and its components. You can email me at amlanc@achakladar.com