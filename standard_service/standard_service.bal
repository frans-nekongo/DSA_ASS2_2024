// import ballerina/io;
import ballerina/log;
import ballerina/sql;
import ballerina/time;
import ballerina/uuid;
import ballerinax/kafka;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

type StandardDeliveryRequestData record {
    string customerName;
    string customerContact;
    string fromTown;
    string toTown;
    string pickupDate;
    string pickupSlot;
    string deliveryType;
};

type TownDeliveryRecord record {
    int id;
    string Town;
    string Date;
    string? Slot_1;
    string? Slot_2;
    string? Slot_3;
    string? Slot_4;
    string? Slot_5;
    string? Slot_6;
    string? Slot_7;
    string? Slot_8;
    string? Slot_9;
    string? Slot_10;
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

type TownDeliveryTable record {

};

function insertIntoTownDeliveryTable(StandardDeliveryRequestData request, string packageId) returns string|error {
    // Initialize the MySQL client
    mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");

    log:printInfo("Connecting to the database to (insertIntoTownDeliveryTable)");

    // Check if the row for the town and date already exists
    sql:ParameterizedQuery selectQuery = `SELECT * FROM Town_Delivery_table 
                                           WHERE Town = ${request.fromTown} AND Date = ${request.pickupDate};`;
    log:printInfo("Executing SELECT query: ");

    // Execute the query and get the result stream
    stream<TownDeliveryTable, sql:Error?> resultStream = mysqlClient->query(selectQuery);
    log:printInfo("Executed SELECT query for town and date.");

    boolean rowExists = false;

    // Process the result stream
    sql:Error? forEach = resultStream.forEach(function(TownDeliveryTable deliveryTable) {
        rowExists = true;
        log:printInfo("Row exists, processing update for Slot 1...");

        // Update Slot 1
        sql:Error? slot1 = updateSlot1(packageId, request.fromTown, request.pickupDate);
    });

    if (forEach is sql:Error) {
        log:printError("Error processing result stream", forEach);
    } else {
        log:printInfo("Completed processing result stream.");
    }

    check resultStream.close();
    log:printInfo("Closed result stream.");

    // If the row does not exist, insert a new row for Slot 1
    if (!rowExists) {
        log:printInfo("Row does not exist. Inserting new row for Slot 1.");
        sql:ParameterizedQuery insertQuery = `INSERT INTO Town_Delivery_table (Town, Date, Slot_1) 
                                              VALUES (${request.fromTown}, ${request.pickupDate}, ${packageId});`;

        log:printInfo("Executing INSERT query: ");
        sql:ExecutionResult|sql:Error insertResult = mysqlClient->execute(insertQuery);

        if (insertResult is sql:Error) {
            log:printError("Error executing insert query: ", insertResult);
            return insertResult; // Handle the error accordingly
        }
        log:printInfo("Inserted new row successfully for Slot 1.");
    }

    // Close the database connection
    check mysqlClient.close();
    log:printInfo("Closed MySQL connection.");

    log:printInfo("Delivery set for: " + request.pickupDate.toString());
    return "Delivery set for: " + request.pickupDate.toString();
}

// Function to update Slot 1
function updateSlot1(string packageId, string town, string date) returns sql:Error? {
    mysql:Client mysqlClient =  check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");

    sql:ParameterizedQuery updateQuery = `UPDATE Town_Delivery_table 
                                          SET Slot_1 = ${packageId} 
                                          WHERE Town = ${town} AND Date = ${date};`;
    log:printInfo("Executing UPDATE query for Slot 1: ");
    sql:ExecutionResult updateResult = check mysqlClient->execute(updateQuery);
    

    log:printInfo("Updated Slot 1 successfully.");
   
}


function insertIntoRequestTable(StandardDeliveryRequestData request) returns string|error {
    log:printInfo("Connecting to the database to (insertIntoRequestTable)");

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

    log:printInfo("insertIntoRequestTable package : " + packageId.toString());
    
    // insert Into Town_Delivery_Table
    string|error insertIntoTownDeliveryTableResult = insertIntoTownDeliveryTable(request,packageId);

    return "insertIntoRequestTable package : " + packageId.toString();

}

// function insertIntoTownDeliveryTable2(StandardDeliveryRequestData request, string packageId) returns string|error {
//     // Initialize the MySQL client
//     mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");

//     log:printInfo("Connecting to the database to (insertIntoTownDeliveryTable)");

//     // Check if the row for the town and date already exists
//     sql:ParameterizedQuery selectQuery = `SELECT * FROM Town_Delivery_table 
//                                            WHERE Town = ${request.fromTown} AND Date = ${request.pickupDate};`;

//     // Execute the query and get the result stream
//     stream<TownDeliveryTable, sql:Error?> resultStream = mysqlClient->query(selectQuery);

//     boolean rowExists = false;

//     // Process the result stream without returning an error from the lambda function
//     sql:Error? forEach = resultStream.forEach(function(TownDeliveryTable deliveryTable) {
//         rowExists = true;

//         // If the row exists, insert the package ID into the correct slot
//         string slotColumn = "Slot_" + request.pickupSlot.toString();
//         sql:ParameterizedQuery updateQuery = `UPDATE Town_Delivery_table 
//                                               SET ${slotColumn} = ${packageId} 
//                                               WHERE Town = ${request.fromTown} AND Date = ${request.pickupDate};`;

//         // Execute the update query and handle errors outside of the forEach
//         var updateResult = mysqlClient->execute(updateQuery);
//         if (updateResult is error) {
//             log:printError("Error while updating delivery table", updateResult);
//         }
//     });
//     if forEach is sql:Error {

//     }

//     check resultStream.close();

//     // If the row does not exist, insert a new row
//     if (!rowExists) {
//         sql:ParameterizedQuery insertQuery = `INSERT INTO Town_Delivery_table (Town, Date, Slot_${request.pickupSlot}) 
//                                               VALUES (${request.fromTown}, ${request.pickupDate}, ${packageId});`;

//         // Execute the insert query and check for errors
//         _ = check mysqlClient->execute(insertQuery);
//     }

//     // Close the database connection
//     check mysqlClient.close();

//     log:printInfo("delivery set for : " + request.pickupDate.toString());
//     return "delivery set for : " + request.pickupDate.toString();
// }