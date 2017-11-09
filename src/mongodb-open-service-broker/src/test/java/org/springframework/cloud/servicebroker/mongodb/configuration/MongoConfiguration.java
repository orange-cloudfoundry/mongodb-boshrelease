package org.springframework.cloud.servicebroker.mongodb.configuration;

import org.springframework.boot.autoconfigure.EnableAutoConfiguration;
import org.springframework.boot.autoconfigure.mongo.embedded.EmbeddedMongoAutoConfiguration;
import org.springframework.context.annotation.Configuration;

/**
 * Created by ijly7474 on 17/10/17.
 */
@Configuration
@EnableAutoConfiguration(exclude = {EmbeddedMongoAutoConfiguration.class})
public class MongoConfiguration {




}
