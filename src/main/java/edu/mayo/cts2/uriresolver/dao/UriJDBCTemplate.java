package edu.mayo.cts2.uriresolver.dao;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStream;
import java.io.InputStreamReader;
import java.io.Reader;
import java.sql.SQLException;
import java.util.List;

import javax.sql.DataSource;

import org.apache.log4j.Logger;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.support.rowset.SqlRowSet;



public class UriJDBCTemplate implements UriDAO {
	private DataSource dataSource;
	private JdbcTemplate jdbcTemplateObject;
	private static Logger logger = Logger.getLogger(UriJDBCTemplate.class);
	private static final String NULL_VALUE = "null";
	
	@Override
	public void setDataSource(DataSource ds) {
		this.dataSource = ds;
		this.jdbcTemplateObject = new JdbcTemplate(dataSource);
	}
	

	@Override
	public int checkDataSource(DataSource ds) {
		int code = 0;
		try {
			ds.getConnection();
		} catch (SQLException e) {
			String msg = e.getMessage();
			logger.error("Error connecting to data source: " + msg + "\n");
			return code;
		}
		return code;
	}
	
	private String createSelectFields(String versionOf, String identifier){
		String sql = "";
		sql += "SELECT ";
		sql += "um.resourcetype ResourceType, ";
		sql += "um.resourcename ResourceName, ";
		sql += "um.resourceuri ResourceURI, ";
		sql += "um.baseentityuri BaseEntityURI, ";
		sql += versionOf + " VersionOf, ";
		sql += identifier + " Identifier ";
		return sql;
	}
	
	private String createOnResourceTypeAndResourceNameMatch(String table1, String table2){
		String sql = "ON  ";
		sql += "( ";
		sql += table1 + ".resourcetype = " + table2 + ".resourcetype ";
		sql += "  AND ";
		sql += table1 + ".resourcename = " + table2 + ".resourcename ";
		sql += ") ";
		return sql;
	}

	private String createWhereTypeAndNameMatch(String table, String type, String name) {
		String sql = "WHERE  ";
		sql += table + ".resourcetype =  '" + type + "' ";
		sql += "AND ";
		sql += table + ".resourcename = '" + name + "' ";
		return sql;
	}


	@Override
	public String getIdentifierByID(String type, String id){
		String resourceName = "";
		String sql = createSelectFields(NULL_VALUE, "im.identifier");
	   
		sql += "FROM urimap um ";											   
		sql += "LEFT JOIN identifiermap im ";
		
		sql += this.createOnResourceTypeAndResourceNameMatch("im", "um");

		sql += " WHERE"; 
		sql += "   um.resourcetype = '" + type + "'";
		sql += "   AND";
		sql += "   (";
		sql += "     um.resourcename = '" + id + "'";
		sql += "     OR";
		sql += "     im.identifier = '" + id + "'";
		sql += "   )";
	   
		SqlRowSet data = this.jdbcTemplateObject.queryForRowSet(sql);		
		
		if(data.next()){
			resourceName = data.getString("ResourceName");
		}
	   
		return resourceName;
	}
	
	@Override
	public String getVersionIdentifierByVersionID(String type, String resourceName, String versionID){
		String versionName = "";
		String sql = "";
		sql += "SELECT ";
		sql += "VersionName ";
	   
		sql += "FROM versionmap ";

		sql += " WHERE"; 
		sql += "   ResourceType = '" + type + "'";
		sql += "   AND ";
		sql += "   ResourceName = '" + resourceName + "'";
		sql += "   AND ";
		sql += "   VersionID = '" + versionID + "'";
	   
		SqlRowSet data = this.jdbcTemplateObject.queryForRowSet(sql);		
		
		if(data.next()){
			versionName = data.getString("VersionName");
		}
	   
		return versionName;
	}	
	

	
	@Override
	public UriResults getURIMapByIdentifier(String type, String identifier){
		String sql = createSelectFields(NULL_VALUE, NULL_VALUE);

		sql += "FROM urimap um ";
		sql += this.createWhereTypeAndNameMatch("um", type, identifier);

		List<UriResults> data = this.jdbcTemplateObject.query(sql, new UriResultsMapper());
	   
		if(!data.isEmpty()){
			return data.get(0);
		}
		
		return null;
	}
	


	@Override
	public UriResults getURIMapIdentifiers(String type, String identifier){
		String sql = createSelectFields(NULL_VALUE, "im.identifier");
    
		sql += "FROM "; 
		sql += "urimap um "; 

		sql += "LEFT JOIN  ";
		sql += "identifiermap im ";
		  
		sql += this.createOnResourceTypeAndResourceNameMatch("im", "um");
		sql += this.createWhereTypeAndNameMatch("um", type, identifier);
		
		List<UriResults> data = this.jdbcTemplateObject.query(sql, new UriResultsMapper());
	   
		if(!data.isEmpty()){
			return data.get(0);
		}

		return null;
	}

	@Override
	public UriResults getURIMapByVersionIdentifier(String type, String identifier, String versionID){
		String sql = createSelectFields(NULL_VALUE, NULL_VALUE);

		sql += "FROM urimap um ";


		sql += "INNER JOIN  ";
		sql += "versionmap vm ";
		  
		sql += this.createOnResourceTypeAndResourceNameMatch("um", "vm");
		sql += this.createWhereTypeAndNameMatch("vm", type, identifier);
   
		sql += "AND ";
		sql += "(";
		sql += "vm.versionid = '" + versionID + "' ";
		sql += "OR ";
		sql += "vm.resourcename = '" + versionID + "') ";
		
		List<UriResults> data = this.jdbcTemplateObject.query(sql, new UriResultsMapper());

		if(!data.isEmpty()){
			return data.get(0);
		}
		
		return null;
	}
	
	
	@Override
	public UriResults getURIMapVersionIdentifiers(String type, String identifier){
		String sql = createSelectFields("vm.resourcename", "vm.versionid");
		
		sql += "FROM "; 
		sql += "urimap um "; 

		sql += "LEFT JOIN  ";
		sql += "versionmap vm ";
		  
		sql += this.createOnResourceTypeAndResourceNameMatch("um", "vm");
		sql += this.createWhereTypeAndNameMatch("um", type, identifier);
			
		List<UriResults> data = this.jdbcTemplateObject.query(sql, new UriResultsMapper());
	   
		if(!data.isEmpty()){
			return data.get(0);
		}
		
		return null;
	}


	public boolean importData() {
		String sql = "";
		BufferedReader bufferedReader =  null;
		Reader reader = null;
		try{
			InputStream in =UriJDBCTemplate.class.getResourceAsStream("/uriresolver.sql");
			reader = new InputStreamReader(in, "UTF-8");
            bufferedReader = new BufferedReader(reader);
            while (bufferedReader.ready()) {
            	String line = bufferedReader.readLine().trim(); 
 				if (this.isSQLCode(line)) {
 					sql += this.convertToH2(line);
 				}
            }
            bufferedReader.close();
            reader.close(); 
		} catch (IOException e) {
			logger.error("Error while importing data to in memory database: " + e.getMessage());
			return false;
		} finally {
			try {
				if(bufferedReader != null){
					bufferedReader.close();
				} 
				if(reader != null){
					reader.close();
				}
			} catch (IOException ex) {
				logger.error("Error while closing access to in memory database: " + ex.getMessage());
				return true;
			}
		}
			
		this.jdbcTemplateObject.execute(sql);
		return true;		
	}


	private String convertToH2(String mySQLLine) {
		String [] stringsToRemove = {"`", " COLLATE utf8_bin", " CHARACTER SET utf8", " COLLATE utf8_unicode_ci", " ENGINE=InnoDB DEFAULT CHARSET=utf8 COLLATE=utf8_bin"};
		String h2Line = mySQLLine.replaceAll("\\\\'", "''");
		for(int i=0; i < stringsToRemove.length; i++){ 						
			h2Line = h2Line.replaceAll(stringsToRemove[i], "");
		}
		return h2Line + "\n";
	}


	private boolean isSQLCode(String line) {
		String [] commentIdentifiers = {"--", "//", "#", "/*", "LOCK", "UNLOCK"};
		for(int i=0; i < commentIdentifiers.length; i++){
			if(line.startsWith(commentIdentifiers[i])){
				return false;
			}
		}
		return true;
	}
}
