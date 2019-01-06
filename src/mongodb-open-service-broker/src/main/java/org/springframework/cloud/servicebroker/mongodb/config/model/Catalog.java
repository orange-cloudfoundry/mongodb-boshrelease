package org.springframework.cloud.servicebroker.mongodb.config.model;

import java.util.List;

public class Catalog {

    private List<Service> services;

    public Catalog() {
    }

    public List<Service> getServices() {
        return services;
    }

}
