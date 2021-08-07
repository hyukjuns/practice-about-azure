import java.sql.*;
class jdbc { 
    public static void main(String argv[]) {
     try { Class.forName("org.gjt.mm.mysql.Driver"); 
          System.out.println("jdbc driver loaded"); 
     } 
     catch (ClassNotFoundException e) {
          System.out.println(e.getMessage()); 
     } 
     try { 
         String url="jdbc:mysql://DBSERVERURL:3306/mysql"; 
         Connection con = DriverManager.getConnection(url,"root","PASSWORD"); 
        System.out.println("mysql connected"); 
        Statement stmt = con.createStatement();
        ResultSet rs = stmt.executeQuery("select user from user where user='root'"); 
     while(rs.next()) { 
                String no = rs.getString(1); String tblname = rs.getString(1);
                System.out.println("no = " + no);
                System.out.println("tblname= "+ tblname); 
            } 
        stmt.close(); con.close(); 
    } 
    catch(java.lang.Exception ex) 
    { 
        ex.printStackTrace();
    } 
    } 
}

