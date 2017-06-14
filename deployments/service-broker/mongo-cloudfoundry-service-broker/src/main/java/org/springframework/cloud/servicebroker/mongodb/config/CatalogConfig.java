package org.springframework.cloud.servicebroker.mongodb.config;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.cloud.servicebroker.model.Catalog;
import org.springframework.cloud.servicebroker.model.Plan;
import org.springframework.cloud.servicebroker.model.ServiceDefinition;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class CatalogConfig {
	
	@Bean
	public Catalog catalog() {
		return new Catalog(Collections.singletonList(
				new ServiceDefinition(
						getEnvOrDefault("SERVICE_ID","mongodb-service-broker"), //env variable
						getEnvOrDefault("SERVICE_NAME","mongodb"), //env variable
						"A shared MongoDB database on demand.",
						true,
						false,
						Collections.singletonList(
								new Plan("mongo-plan",
										"default",
										"This is a default mongo plan.  All services are created equally.",
										getPlanMetadata())),
						Arrays.asList("mongodb", "document"),
						getServiceDefinitionMetadata(),
						null,
						null)));
	}
	
/* Used by Pivotal CF console */

	private Map<String, Object> getServiceDefinitionMetadata() {
		Map<String, Object> sdMetadata = new HashMap<>();
		sdMetadata.put("displayName", "MongoDB 3.0");
		//sdMetadata.put("imageUrl", "http://info.mongodb.com/rs/mongodb/images/MongoDB_Logo_Full.png");
		sdMetadata.put("imageUrl", "https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcR9mtOVRxVp_1TgQ3b4UnawlWqUkw86oNRDvQAFz3gCuZNMrtPqYw");
		sdMetadata.put("longDescription", "MongoDB is a free and open-source cross-platform document-oriented database program. Classified as a NoSQL database program, MongoDB uses JSON-like documents with schemas. MongoDB is developed by MongoDB Inc. and is free and open-source, published under a combination of the GNU Affero General Public License and the Apache License.");
		sdMetadata.put("providerDisplayName", "Orange");
		sdMetadata.put("documentationUrl", "https://github.com/spring-cloud-samples/cloudfoundry-mongodb-service-broker");
		sdMetadata.put("supportUrl", "https://github.com/spring-cloud-samples/cloudfoundry-mongodb-service-broker");
		return sdMetadata;
	}
	
	private Map<String,Object> getPlanMetadata() {
		Map<String,Object> planMetadata = new HashMap<>();
		//planMetadata.put("costs", getCosts());
		planMetadata.put("bullets", getBullets());
		return planMetadata;
	}

	private List<Map<String,Object>> getCosts() {
		Map<String,Object> costsMap = new HashMap<>();
		
		Map<String,Object> amount = new HashMap<>();
		amount.put("usd", 0.0);
	
		costsMap.put("amount", amount);
		costsMap.put("unit", "MONTHLY");
		
		return Collections.singletonList(costsMap);
	}
	
	private List<String> getBullets() {
		return Arrays.asList("Shared MongoDB server", 
				"100 MB Storage (not enforced)", 
				"40 concurrent connections (not enforced)");
	}

	private String getEnvOrDefault(final String variable, final String defaultValue){
		String value = System.getenv(variable);
		if(value != null){
			return value;
		}
		else{
			return defaultValue;
		}
	}
}
