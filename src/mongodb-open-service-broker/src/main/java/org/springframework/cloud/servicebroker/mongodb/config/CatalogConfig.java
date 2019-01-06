package org.springframework.cloud.servicebroker.mongodb.config;

import java.util.Arrays;
import java.util.Collections;
import java.util.HashMap;
import java.util.List;
import java.util.Map;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.cloud.servicebroker.model.Catalog;
import org.springframework.cloud.servicebroker.model.Plan;
import org.springframework.cloud.servicebroker.model.ServiceDefinition;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;

@Configuration
public class CatalogConfig {

	@Value("${catalog_yml}")
	private String catalogYml;

	public String getCatalog(){
		return catalogYml;
	}

	@Bean
	public Catalog catalog() {
		Catalog catalog;
		if (catalogYml == null) { //hard coded catalog is returned
			catalog = new Catalog(Collections.singletonList(
					new ServiceDefinition(
							"mongodb-service-broker",
							"MongoDB 3.4.x for Cloud Foundry",
							"A MongoDB database on demand on shared cluster.",
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
		}else{
			CatalogYmlReader catalogYmlReader = new CatalogYmlReader();
			List<ServiceDefinition> serviceDefinitions = catalogYmlReader.getServiceDefinitions(catalogYml);
			catalog = new Catalog (serviceDefinitions);
		}
		return catalog;
	}

	private Map<String, Object> getServiceDefinitionMetadata() {
		Map<String, Object> sdMetadata = new HashMap<>();
		sdMetadata.put("displayName", "MongoDB");
		sdMetadata.put("imageUrl", "https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcR9mtOVRxVp_1TgQ3b4UnawlWqUkw86oNRDvQAFz3gCuZNMrtPqYw");
		sdMetadata.put("longDescription", "MongoDB is a free and open-source cross-platform document-oriented database program. Classified as a NoSQL database program, MongoDB uses JSON-like documents with schemas. MongoDB is developed by MongoDB Inc. and is free and open-source, published under a combination of the GNU Affero General Public License and the Apache License.");
		sdMetadata.put("providerDisplayName", "Orange");
		sdMetadata.put("documentationUrl", "https://docs.mongodb.com/");
		sdMetadata.put("supportUrl", "https://marketplace.my-company.org/contact-us");
		return sdMetadata;
	}
	
	private Map<String,Object> getPlanMetadata() {
		Map<String,Object> planMetadata = new HashMap<>();
		planMetadata.put("costs", getCosts());
		planMetadata.put("bullets", getBullets());
		return planMetadata;
	}

	private List<Map<String,Object>> getCosts() {
		Map<String,Object> costsMap = new HashMap<>();
		
		Map<String,Object> amount = new HashMap<>();
		amount.put("eur", 10.0);
	
		costsMap.put("amount", amount);
		costsMap.put("unit", "MONTHLY");
		
		return Collections.singletonList(costsMap);
	}
	
	private List<String> getBullets() {
		return Arrays.asList("Shared MongoDB server", 
				"100 MB Storage (not enforced)", 
				"40 concurrent connections (not enforced)");
	}

}
