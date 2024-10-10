// import ballerina/io;
import ballerina/log;
import ballerina/time;
import ballerina/sql;
import ballerinax/kafka;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;
import ballerina/uuid;

type StandardDeliveryRequestData record {
    string customerName;
    string customerContact;
    string fromTown;
    string toTown;
    string pickupDate;
    string pickupSlot;
    string deliveryType;
};

// Database configuration
string dbUser = "RXD";
string dbPassword = "100101";

public function main() returns error? {

    // []]]]]]]]]][][]] consumer section ][ ][][] [] [ ] ]] 
    // Create a consumer for the StandardDeliveryRequest topic
    kafka:Consumer StandardDeliveryRequest = check new (kafka:DEFAULT_URL, {
        groupId: "StandardDeliveryRequestGroup", // Define the group for the consumer
        topics: "StandardDeliveryRequest" // Subscribe to the topic
    });

    while true {
        // Poll for new messages from the StandardDeliveryRequest topic
        StandardDeliveryRequestData[] requests = check StandardDeliveryRequest->pollPayload(15); // Poll with a timeout of 15 seconds

        if (requests.length() > 0) {
            log:printInfo("Received " + requests.length().toString() + "Request from the StandardDeliveryRequest topic.");
        }

        from StandardDeliveryRequestData request in requests
        do {
            // Log the received request
            log:printInfo("Requested from : " + request.fromTown + ", to : " + request.toTown);

            // / []]]]]]]]]][][]] send request to requesttable in db and send the results to the StandardDeliveryReply ][ ][][] [] [ ] ]]

            string StandardDeliveryRequestResult = check insertIntoRequestTable(request);

        };
    }

}

    // Function to process StandardDelivery requests
    // Function to calculate the delivery date by adding 2 days to the pickup date

function deliveryDateCalculator(string pickupDate) returns string|error {
    // Convert the pickup date from string to time:Civil
    time:Civil civilPickupDate = check time:civilFromString(pickupDate + "T00:00:00Z");

    // Convert the civil time to UTC
    time:Utc utcPickupDate = check time:utcFromCivil(civilPickupDate);

    // Add 2 days (172800 seconds) to the UTC time
    time:Utc deliveryUtcDate = time:utcAddSeconds(utcPickupDate, 172800); // 2 days in seconds

    // Convert the delivery UTC date back to a civil time
    time:Civil deliveryCivilDate = time:utcToCivil(deliveryUtcDate);

    // Convert the civil date back to string in the format "YYYY-MM-DD"
    string deliveryDate = check time:civilToString(deliveryCivilDate);

    // Return the delivery date in the format "YYYY-MM-DD"
    return deliveryDate.substring(0, 10); // Extracting only the date part
}

function createPackageID() returns string {
     // Generate a UUID and convert it to a string
    string fullUuid = uuid:createType1AsString();
    
    // Extract the first 4 characters of the UUID
    string packageId = "PackageID-" + fullUuid.substring(0, 4);
    
    // Print the package ID
    log:printInfo("Generated Package ID: " + packageId);

    return packageId;
}


function insertIntoRequestTable(StandardDeliveryRequestData request) returns string|error {
    log:printInfo("insertRequestToDB: Connecting to the database to insert request.");

    mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");
    

    // Create a delivery date 
    string deliveryDate = check deliveryDateCalculator(request.pickupDate);

    // Create a packageID
    string packageId = createPackageID();

    // Create a parameterized query to insert the data into the request table
    // Create an insert query
    sql:ParameterizedQuery insertQuery = `INSERT INTO request_table (Customer_Name, Customer_contact, From_Town, To_Town, 
                                                               Pickup_Date, Pickup_Slot, Delivery_Type, Delivery_Date, Package_ID) 
                                       VALUES (${request.customerName}, ${request.customerContact}, ${request.fromTown}, ${request.toTown}, 
                                               ${request.pickupDate}, ${request.pickupSlot}, ${request.deliveryType}, ${deliveryDate}, ${packageId})`;

    // Log the insert query for debugging
    log:printInfo("insertRequestToDB: Executing insert query.");

    // Execute the insert query
    sql:ExecutionResult executionResult = check mysqlClient->execute(insertQuery);

    // Close the database connection
    check mysqlClient.close();

    log:printInfo("delivery will be delivered on : " + deliveryDate.toString());
    return "delivery will be delivered on : " + deliveryDate.toString();

}
