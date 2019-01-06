package org.springframework.cloud.servicebroker.mongodb.config;

import org.junit.Test;
import org.junit.runner.RunWith;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTestContextBootstrapper;
import org.springframework.cloud.servicebroker.model.ServiceDefinition;
import org.springframework.test.context.BootstrapWith;
import org.springframework.test.context.junit4.SpringJUnit4ClassRunner;
import java.util.List;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

@RunWith(SpringJUnit4ClassRunner.class)
@BootstrapWith(SpringBootTestContextBootstrapper.class)
public class CatalogConfigTest {

    @Autowired
    private CatalogConfig catalogConfig;

    @Test
    public void test() {
        //Given (catalog is defined in test/resources/application.yml

        //When
        String catalogYml = catalogConfig.getCatalog();
        CatalogYmlReader catalogYmlReader = new CatalogYmlReader();
        List<ServiceDefinition> serviceDefinitions = catalogYmlReader.getServiceDefinitions(catalogYml);

        //Then
        assertThat(serviceDefinitions.get(0).getId()).isEqualTo("mongodb-service-broker");
        assertThat(serviceDefinitions.get(0).getName()).isEqualTo("MongoDB 3.4.x for Cloud Foundry");
        assertThat(serviceDefinitions.get(0).getDescription()).isEqualTo("A MongoDB database on demand on shared cluster.");
        assertThat(serviceDefinitions.get(0).isBindable()).isEqualTo(true);
        assertThat(serviceDefinitions.get(0).getPlans().get(0).getId()).isEqualTo("mongo-plan");
        assertThat(serviceDefinitions.get(0).getPlans().get(0).getName()).isEqualTo("default");
        assertThat(serviceDefinitions.get(0).getPlans().get(0).getDescription()).isEqualTo("This is a default mongo plan.  All services are created equally");
        assertThat(serviceDefinitions.get(0).getPlans().get(0).isFree()).isEqualTo(false);
        //bullets
        List listBullets = (List) serviceDefinitions.get(0).getPlans().get(0).getMetadata().get("bullets");
        assertThat(listBullets.get(0)).isEqualTo("100 MB Storage (not enforced)");
        assertThat(listBullets.get(1)).isEqualTo("40 concurrent connections (not enforced)");
        //costs
        Map mapCosts = (Map) serviceDefinitions.get(0).getPlans().get(0).getMetadata().get("costs");
        Map mapAmount = (Map)mapCosts.get("amount");
        Double price = (Double)mapAmount.get("eur");
        assertThat(price).isEqualTo(10.0);
        String period = (String)mapCosts.get("unit");
        assertThat(period).isEqualTo("MONTHLY");
        //displayName
        String displayName = (String)serviceDefinitions.get(0).getPlans().get(0).getMetadata().get("displayName");
        assertThat(displayName).isEqualTo("Default - Shared MongoDB server");

        assertThat(serviceDefinitions.get(0).getTags().get(0)).isEqualTo("mongodb");
        assertThat(serviceDefinitions.get(0).getTags().get(1)).isEqualTo("document");
        assertThat(serviceDefinitions.get(0).getMetadata().get("displayName")).isEqualTo("MongoDB");
        assertThat(serviceDefinitions.get(0).getMetadata().get("imageUrl")).isEqualTo("https://encrypted-tbn1.gstatic.com/images?q=tbn:ANd9GcR9mtOVRxVp_1TgQ3b4UnawlWqUkw86oNRDvQAFz3gCuZNMrtPqYw");
        assertThat(serviceDefinitions.get(0).getMetadata().get("longDescription")).isEqualTo("MongoDB is a free and open-source cross-platform document-oriented database program. Classified as a NoSQL database program, MongoDB uses JSON-like documents with schemas. MongoDB is developed by MongoDB Inc. and is free and open-source, published under a combination of the GNU Affero General Public License and the Apache License.");
        assertThat(serviceDefinitions.get(0).getMetadata().get("providerDisplayName")).isEqualTo("Orange");
        assertThat(serviceDefinitions.get(0).getMetadata().get("documentationUrl")).isEqualTo("https://docs.mongodb.com/");
        assertThat(serviceDefinitions.get(0).getMetadata().get("supportUrl")).isEqualTo("https://contact-us/");
    }
}
