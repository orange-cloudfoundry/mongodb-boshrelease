package org.springframework.cloud.servicebroker.mongodb.config;

import java.net.UnknownHostException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.data.mongodb.repository.config.EnableMongoRepositories;

import com.mongodb.MongoClient;
import com.mongodb.MongoCredential;
import com.mongodb.ServerAddress;

@Configuration 
@EnableMongoRepositories(basePackages = "org.springframework.cloud.servicebroker.mongodb.repository")
public class MongoConfig {

	private Logger logger = LoggerFactory.getLogger(MongoConfig.class);
	
	@Value("${mongodb.host:localhost}")
	private String host;

	@Value("${mongodb.port:27017}")
	private int port;

	@Value("${mongodb.username:admin}")
	private String username;

	@Value("${mongodb.password:password}")
	private String password;

	@Value("${mongodb.authdb:admin}")
	private String authSource;

	@Bean
	public MongoClient mongoClient() throws UnknownHostException {
		final MongoCredential credential = MongoCredential.createScramSha1Credential(username, authSource, password.toCharArray());
		//List<ServerAddress> hosts = Arrays.asList();  
		logger.info("**mongoClient " + host.toString() + ":" + port + 
				" (" + username + "/" + authSource + "/" + password + ")"); 
		MongoClient mongoClient = null;
		List<ServerAddress> hosts = new ArrayList<>();
		if(host.contains(",")){
			logger.info("Replica set mode");
			
			String[] s_hosts = host.split(",");
			for (int i = 0; i < s_hosts.length; i++) {
				if( s_hosts[i] != null && !s_hosts[i].isEmpty()){
					hosts.add(new ServerAddress(s_hosts[i], 27017));
				}
			}
			mongoClient = new MongoClient(hosts, Arrays.asList(credential));

		}else{
			logger.info("Single mode");

			mongoClient = new MongoClient(new ServerAddress(host, port), Arrays.asList(credential));
		}
		return mongoClient;
	}


}
