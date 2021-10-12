package org.springframework.cloud.servicebroker.mongodb.service;

import java.util.Arrays;
import java.util.HashMap;
import java.util.Map;

import org.bson.Document;
import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.servicebroker.mongodb.exception.MongoServiceException;
import org.springframework.stereotype.Service;

import com.mongodb.BasicDBObject;
import com.mongodb.MongoClient;
import com.mongodb.MongoException;
import com.mongodb.ServerAddress;
import com.mongodb.client.MongoCollection;
import com.mongodb.client.MongoDatabase;

/**
 * Utility class for manipulating a Mongo database.
 *
 * @author sgreenberg@pivotal.io 
 *
 */
@Service
public class MongoAdminService {

	private Logger logger = LoggerFactory.getLogger(MongoAdminService.class);

	private MongoClient client;
	
	@Value("${mongodb.authdb:admin}")
	private String adminDatabase;
	
	@Value("${mongodb.username:admin}")
	private String adminUsername;

	@Value("${mongodb.host:localhost}")
	private String host;

	@Value("${mongodb.port:27017}")
	private int port;

	@Value("${mongodb.hamode:false}")
	private boolean hamode;

	@Autowired
	public MongoAdminService(MongoClient client) {
		this.client = client;
	}

	public boolean databaseExists(String databaseName) throws MongoServiceException {

		try {
			for(String dbname : client.listDatabaseNames()){
				if(dbname.equals(databaseName)){
					return true;
				}
			}
			
			return false;
		} catch (MongoException e) {
			throw handleException(e);
		}
	}

	public void deleteDatabase(String databaseName) throws MongoServiceException {

		try{
			client.getDatabase(adminDatabase);
			client.dropDatabase(databaseName);
		} catch (MongoException e) {
			throw handleException(e);
		}
	}

	public MongoDatabase createDatabase(String databaseName) throws MongoServiceException {

		try {
			addDbOwnerRole(databaseName);
			
			MongoDatabase db = client.getDatabase(databaseName);
			db.createCollection("tmp");
			// save into a collection to force DB creation.
			MongoCollection<Document> col = db.getCollection("tmp");
			Document document = new Document("tmp", "Use to persist the database");
			
			col.insertOne(document);
			// drop the collection so the db is empty
			// Fix: disable drop to keep database (mongoDB 3.4)
			logger.info("Database " + databaseName + " is created");
			//col.drop();

			return db;
		} catch (MongoException e) {
			// try to clean up and fail
			try {
				deleteDatabase(databaseName);
			} catch (MongoServiceException ignore) {}
			throw handleException(e);
		}
	}
	
	
	private void addDbOwnerRole(String databaseName){

		MongoDatabase db = client.getDatabase(adminDatabase);
		Map<String, Object> roles = new BasicDBObject();
		roles.put("role", "dbOwner");
		roles.put("db", databaseName);
		
		Map<String, Object> commandArguments = new BasicDBObject();
	    commandArguments.put("grantRolesToUser", adminUsername);
	    commandArguments.put("roles", Arrays.asList(roles));
	    BasicDBObject grantRolesToUserCmd = new BasicDBObject(commandArguments);
	    
	    Document result = db.runCommand(grantRolesToUserCmd);
		if (result.getDouble("ok") != 1.0d) {
			throw handleException(new MongoServiceException(result.toString()));
		}
	}

	public void createUser(String database, String username, String password) throws MongoServiceException {

		try {
			
			MongoDatabase db = client.getDatabase(database);
			Map<String, Object> roles = new BasicDBObject();
			roles.put("role", "readWrite");
			roles.put("db", database);

			Map<String, Object> commandArguments = new BasicDBObject();
		    commandArguments.put("createUser", username);
		    commandArguments.put("pwd", password);
		   
		    commandArguments.put("roles", Arrays.asList(roles));
		    BasicDBObject createUserCmd = new BasicDBObject(commandArguments);
			
		    logger.info("createUser " + createUserCmd.toString() );
			Document result = db.runCommand(createUserCmd);
			if (result.getDouble("ok") != 1.0d) {
				throw handleException(new MongoServiceException(result.toString()));
			}
		} catch (MongoException e) {
			throw handleException(e);
		}
	}

	public void deleteUser(String database, String username) throws MongoServiceException {

		try {
			MongoDatabase db = client.getDatabase(database);
			Document result = db.runCommand(new BasicDBObject("dropUser", username));
			if (result.getDouble("ok") != 1.0d) {
				throw handleException(new MongoServiceException(result.toString()));
			}
		} catch (MongoException e) {
			throw handleException(e);
		}
	}

	public String getConnectionString(String database, String username, String password) {
		
		StringBuilder strB = new StringBuilder();
		strB.append("mongodb://")
		.append(username)
		.append(":")
		.append(password)
		.append("@")
		.append(getServerAddresses())
		.append("/")
		.append(database);
		
		if(System.getenv("MONGODB_REPLICASET_NAME") != null && ! System.getenv("MONGODB_REPLICASET_NAME").isEmpty()){
			strB.append("?replicaSet=")
			.append(System.getenv("MONGODB_REPLICASET_NAME"));
			//.append("&readPreference=secondary");
		}
		
		return strB.toString();
	}

	public String getHAConnectionString(String database, String username, String password, String address, int port) {

		StringBuilder strB = new StringBuilder();
		strB.append("mongodb://")
				.append(username)
				.append(":")
				.append(password)
				.append("@")
				.append(address)
				.append(":")
				.append(port)
				.append("/")
				.append(database);
		strB.append("?directConnection=true");
		return strB.toString();
	}

	public String getServerAddresses() {

		StringBuilder builder = new StringBuilder();
		for (ServerAddress address : client.getAllAddress()) {
			builder.append(address.getHost())
					.append(":")
					.append(address.getPort())
					.append(",");
		}
		if (builder.length() > 0) {
			builder.deleteCharAt(builder.length()-1);
		}
		return builder.toString();
	}

	public Map<String, Object> getCredentialsMap(String database, String username, String password) {

		Map<String, Object> credentials = new HashMap<>();
		String[] s_hosts = host.split(",");
		credentials.put("database", (Object) database);
		credentials.put("username", (Object) username);
		credentials.put("password", (Object) password);
		if (hamode == false){
			credentials.put("uri", (Object) this.getConnectionString(database, username, password));
			credentials.put("hostname", (Object) this.getServerAddresses());
		}else{
			String uri = this.getHAConnectionString(database, username, password,s_hosts[0],port); // first address in configuration file
			credentials.put("uri", (Object) uri);
			String secondary_uri = this.getHAConnectionString(database, username, password,s_hosts[1],port); //second address in configuration
			credentials.put("secondary_uri", (Object) secondary_uri);
			credentials.put("hostname", (Object) s_hosts[0]);
			credentials.put("hostname_secondary", (Object) s_hosts[1]);
		}
		return credentials;
	}

	private MongoServiceException handleException(Exception e) {
		logger.warn(e.getLocalizedMessage(), e);
		return new MongoServiceException(e.getLocalizedMessage());
	}




}
