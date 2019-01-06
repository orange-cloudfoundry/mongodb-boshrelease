package org.springframework.cloud.servicebroker.mongodb.config.mapper;

import org.springframework.cloud.servicebroker.model.ServiceDefinition;
import org.springframework.cloud.servicebroker.mongodb.config.model.Service;

import java.util.ArrayList;
import java.util.List;

/**
 * Service internal mapper
 */
public class ServiceMapper {

    public static ServiceDefinition toServiceDefinition(Service service) {
        return new ServiceDefinition(service.getId().toString(),
                service.getName(),
                service.getDescription(),
                service.getBindable(),
                service.getPlanUpdateable(),
                PlanMapper.toServiceBrokerPlans(service.getPlans()),
                service.getTags(),
                service.getMetadata(),
                service.getRequires(),
                null);
    }


    public static List<ServiceDefinition> toServiceDefinitions(List<Service> service) {
        List<ServiceDefinition> serviceDefinitionList = new ArrayList<>();
        for (Service sp : service){
            ServiceDefinition serviceDefinition = toServiceDefinition(sp);
            serviceDefinitionList.add(serviceDefinition);
        }
        return serviceDefinitionList;
    }

}
