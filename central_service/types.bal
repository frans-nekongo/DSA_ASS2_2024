// AUTO-GENERATED FILE.
// This file is auto-generated by the Ballerina OpenAPI tool.

public type DeliveryRequest record {
    # Name of the customer
    string customerName;
    # Contact information of the customer
    string customerContact;
    # Town where the package will be picked up
    string fromTown;
    # Town where the package will be delivered
    string toTown;
    # Date for the package pickup
    string pickupDate;
    # The time slot for the pickup
    string pickupSlot;
    # Type of delivery requested
    "Normal"|"Express"|"International" deliveryType;
};

public type inline_response_201 record {
    # The generated package ID for the request.
    string packageId?;
};

public type inline_response_200_1 record {
    # Unique ID for the delivery request
    string requestId?;
    # Name of the customer
    string customerName?;
    # Contact information of the customer
    string customerContact?;
    # Town where the package will be picked up
    string fromTown?;
    # Town where the package will be delivered
    string toTown?;
    # Date for the package pickup
    string pickupDate?;
    # The time slot for the pickup
    string pickupSlot?;
    # Type of delivery requested
    "Normal"|"Express"|"International" deliveryType?;
    # Estimated date for the delivery
    string deliveryDate?;
};


