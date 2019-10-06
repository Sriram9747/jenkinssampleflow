<%-- 
    Document   : index
    Created on : Apr 29, 2018, 10:46:47 AM
    Author     : amlan
--%>

<%@page contentType="text/html" pageEncoding="UTF-8"%>
<!DOCTYPE html>
<html>
    <head>
        <meta http-equiv="Content-Type" content="text/html; charset=UTF-8">
        <title>Login Page..Welcome</title>
    </head>
    <body>
        <h1>Login Form in a Docker(PROD)!</h1>
        <table border="0">
            <thead>
                <tr>
                    <th>Please enter a Name below:</th>
                </tr>
            </thead>
            <tbody>
                <tr>
                    <td>
                        <a>Enter User Name for Login : </a>
                        <form action="${pageContext.request.contextPath}/callmethods" method="post" name="sbmtdata">
                            <input type="text" name="usrinpt" value="<%= request.getAttribute("outputvalue") %>" />
                            <input type="submit" value="Submit" name="sbmt" />
                            <!--<input type="text" name="otpt" disabled="disabled"  value="<%= request.getAttribute("outputvalue") %>" />-->
                            
                        </form>
                        
                        
                    </td>
                    <td></td>
                    <td>
                        
                    </td>
                </tr>
                <tr></tr>
                <tr>
                    
                    <td>
                        <a>Your User Name</a></br>
                        <input type="text" name="otpt1" disabled="disabled"  value="<%= request.getAttribute("outputvalue") %>"</td>
                    
                    <td></td>
                    <td></td>
                </tr>
            </tbody>
        </table>

    </body>
</html>
