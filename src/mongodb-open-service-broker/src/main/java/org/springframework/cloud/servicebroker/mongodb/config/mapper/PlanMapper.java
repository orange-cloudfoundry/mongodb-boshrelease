package org.springframework.cloud.servicebroker.mongodb.config.mapper;



import org.springframework.cloud.servicebroker.mongodb.config.model.Plan;

import java.util.ArrayList;
import java.util.List;

/**
 * Service plan internal mapper
 *
 */
public class PlanMapper {


    public static org.springframework.cloud.servicebroker.model.Plan toServiceBrokerPlan(Plan plan) {

        return new org.springframework.cloud.servicebroker.model.Plan(plan.getId(),
                plan.getName(),
                plan.getDescription(),
                plan.getMetadata() ,
                plan.getFree());
    }

    public static List<org.springframework.cloud.servicebroker.model.Plan> toServiceBrokerPlans(List<Plan> planProperties) {
        List<org.springframework.cloud.servicebroker.model.Plan> planList = new ArrayList<>();
        for (Plan pp : planProperties){
            org.springframework.cloud.servicebroker.model.Plan plan = toServiceBrokerPlan(pp);
            planList.add(plan);
        }
        return planList;
    }
}
