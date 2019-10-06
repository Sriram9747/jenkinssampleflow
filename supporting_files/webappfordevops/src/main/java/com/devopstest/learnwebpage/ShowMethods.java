/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */

package com.devopstest.learnwebpage;
import javax.servlet.http.HttpServletRequest;
import javax.swing.JOptionPane; 
/**
 *
 * @author amlan
 */
public class ShowMethods {
    
    public HttpServletRequest testshow(HttpServletRequest request){
        System.out.println("It is working_in_method");
        //request.getParameter("sbmt");
        String something =  (String)request.getAttribute("usrinpt");
        String btn1=request.getParameter("usrinpt");
        request.setAttribute(btn1, "aa");
        String btn2=request.getParameter("otpt");
        request.setAttribute(btn2, "aa");
        System.out.println(btn1);
        //JOptionPane.showMessageDialog(null, "My Goodness, this is so concise");
        return request;
    }
    
    
}
