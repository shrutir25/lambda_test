/*
 * To change this license header, choose License Headers in Project Properties.
 * To change this template file, choose Tools | Templates
 * and open the template in the editor.
 */
package uwt;

/**
 *
 * @author wlloyd
 */
public class Response {
    String value;
    
    public String getValue()
    {
        return value;
    }
    public void setValue(String value)
    {
        this.value = value;
    }
    public Response(String value)
    {
        this.value = value;
    }
    public Response()
    {
        
    }
}
