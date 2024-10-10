// AUTO-GENERATED FILE.
// This file is auto-generated by the Ballerina OpenAPI tool.

import ballerina/http;
import ballerina/log;
import ballerina/uuid;
import ballerinax/kafka;

listener http:Listener ep0 = new (9090, config = {host: "localhost"});

service / on ep0 {
    // kafka initialisation stuff random here..oh well
    private final kafka:Producer StandardDeliveryRequest;
    private final kafka:Consumer StandardDeliveryReply;

    private final kafka:Producer ExpressDeliveryRequest;
    private final kafka:Consumer ExpressDeliveryReply;

    private final kafka:Producer InternationalDeliveryRequest;
    private final kafka:Consumer InternationalDeliveryResponse;

    function init() returns error? {
        //producer
        self.StandardDeliveryRequest = check new (kafka:DEFAULT_URL);
        //consumer
        self.StandardDeliveryReply = check new (kafka:DEFAULT_URL, {
            groupId: "StandardDeliveryReplyGroup",
            topics: "StandardDeliveryReply"
        });

        //producer
        self.ExpressDeliveryRequest = check new (kafka:DEFAULT_URL);
        //consumer
        self.ExpressDeliveryReply = check new (kafka:DEFAULT_URL, {
            groupId: "ExpressDeliveryReplyGroup",
            topics: "ExpressDeliveryReply"
        });

        //producer
        self.InternationalDeliveryRequest = check new (kafka:DEFAULT_URL);
        //consumer
        self.InternationalDeliveryResponse = check new (kafka:DEFAULT_URL, {
            groupId: "InternationalDeliveryResponseGroup",
            topics: "InternationalDeliveryResponse"
        });

        // Subscribe to the topic
        check self.StandardDeliveryReply->subscribe(["StandardDeliveryReply"]);
        check self.ExpressDeliveryReply->subscribe(["ExpressDeliveryReply"]);
        check self.InternationalDeliveryResponse->subscribe(["InternationalDeliveryResponse"]);

    }

    // # Retrieve the available slots for a specific town and date.
    // #
    // # + return - Availability information for the specified town, date, and slot. 
    // resource function get availabilityCheck(string date, string town, string slot) returns inline_response_200 {
    // }

    // # Retrieve package status by package ID.
    // #
    // # + return - Package information retrieved successfully. 
    // resource function get packageStatus(string packageId) returns inline_response_200_1 {
    // }

    // # Submit a delivery request.
    // #
    // # + return - Delivery request successfully created. 
    resource function post request(@http:Payload DeliveryRequest payload) returns inline_response_201|error {
        // Log the raw data of the payload to see what it looks like
        log:printInfo("Received Request Payload: " + payload.toString());

        // Extract and log the delivery type
        string deliveryType = payload.deliveryType is string ? <string>payload.deliveryType : "";
        log:printInfo("Delivery Type: " + deliveryType);

        // Simulate generating a package ID
        string packageId = "PackageID-" + uuid:createType1AsString();
        log:printInfo("Generated Package ID: " + packageId);

        // Create a delivery request record
        record {
            string customerName;
            string customerContact;
            string fromTown;
            string toTown;
            string pickupDate;
            string pickupSlot;
            string deliveryType;
            string packageId;
        }
        deliveryRequest = {
            customerName: payload.customerName is string ? payload.customerName : "",
            customerContact: payload.customerContact is string ? payload.customerContact : "",
            fromTown: payload.fromTown is string ? payload.fromTown : "",
            toTown: payload.toTown is string ? payload.toTown : "",
            pickupDate: payload.pickupDate is string ? payload.pickupDate : "",
            pickupSlot: payload.pickupSlot is string ? payload.pickupSlot : "",
            deliveryType: deliveryType,
            packageId: packageId
        };

        // Send the delivery request to the appropriate Kafka topic
        if (deliveryType == "Normal") {
            check self.StandardDeliveryRequest->send({
                topic: "StandardDeliveryRequest",
                value: deliveryRequest
            });
        } else if (deliveryType == "Express") {
            check self.ExpressDeliveryRequest->send({
                topic: "ExpressDeliveryRequest",
                value: deliveryRequest
            });
        } else if (deliveryType == "International") {
            check self.InternationalDeliveryRequest->send({
                topic: "InternationalDeliveryRequest",
                value: deliveryRequest
            });
        }

        // Return the generated package ID as the response
        return {
            packageId: packageId
        };
    }

}