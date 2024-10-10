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

// Kafka Producer
kafka:Producer StandardDeliveryReplyProducer = check new (kafka:DEFAULT_URL);

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
    string fullUuid = uuid:createType4AsString();

    // Extract the first 4 characters of the UUID
    string packageId = "PackageID-" + fullUuid.substring(0, 8);

    // Print the package ID
    log:printInfo("Generated Package ID: " + packageId);

    return packageId;
}

type TownDeliveryTable record {
    int id;
    string Town;
    string Date?;
    string Slot_1?;
    string Slot_2?;
    string Slot_3?;
    string Slot_4?;
    string Slot_5?;
    string Slot_6?;
    string Slot_7?;
    string Slot_8?;
    string Slot_9?;
    string Slot_10?;
};

// function insertIntoTownDeliveryTableSlot1(StandardDeliveryRequestData request, string packageId) returns string|error {
//     // Initialize the MySQL client
//     mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");

//     log:printInfo("Connecting to the database to (insertIntoTownDeliveryTableSlot1)");

//     // Check if the row for the town and date already exists
//     sql:ParameterizedQuery selectQuery = `SELECT * FROM Town_Delivery_table 
//                                            WHERE Town = ${request.fromTown} AND Date = ${request.pickupDate};`;
//     log:printInfo("Executing SELECT query: ");

//     // Execute the query and get the result stream
//     stream<TownDeliveryTable, sql:Error?> resultStream = mysqlClient->query(selectQuery);
//     log:printInfo("Executed SELECT query for town and date.");

//     boolean rowExists = false;

//     // Process the result stream
//     sql:Error? forEach = resultStream.forEach(function(TownDeliveryTable deliveryTable) {
//         rowExists = true;
//         log:printInfo("Row exists, updating Slot 1...");

//         // Update Slot 1
//         sql:ParameterizedQuery updateQuery = `UPDATE Town_Delivery_table 
//                                               SET Slot_1 = ${packageId} 
//                                               WHERE Town = ${request.fromTown} AND Date = ${request.pickupDate};`;
//         log:printInfo("Executing UPDATE query for Slot 1: ");
//         sql:ExecutionResult|sql:Error updateResult = mysqlClient->execute(updateQuery);

//         log:printInfo("Updated Slot 1 successfully.");
//     });

//     if (forEach is sql:Error) {
//         log:printError("Error processing result stream", forEach);
//     } else {
//         log:printInfo("Completed processing result stream.");
//     }

//     check resultStream.close();
//     log:printInfo("Closed result stream.");

//     // If the row does not exist, insert a new row for Slot 1
//     if (!rowExists) {
//         log:printInfo("Row does not exist. Inserting new row for Slot 1.");
//         sql:ParameterizedQuery insertQuery = `INSERT INTO Town_Delivery_table 
//                                           (Town, Date, Slot_1, Slot_2, Slot_3, Slot_4, Slot_5, Slot_6, Slot_7, Slot_8, Slot_9, Slot_10) 
//                                           VALUES (${request.fromTown}, ${request.pickupDate}, ${packageId}, 
//                                                   "Available", "Available", "Available", "Available", "Available", 
//                                                   "Available", "Available", "Available", "Available");`;

//         log:printInfo("Executing INSERT query: ");
//         sql:ExecutionResult|sql:Error insertResult = mysqlClient->execute(insertQuery);

//         if (insertResult is sql:Error) {
//             log:printError("Error executing insert query: ", insertResult);
//             return insertResult; // Handle the error accordingly
//         }
//         log:printInfo("Inserted new row successfully for Slot 1.");
//     }

//     // Close the database connection
//     check mysqlClient.close();
//     log:printInfo("Closed MySQL connection.");

//     log:printInfo("Delivery set for: " + request.pickupDate.toString());
//     return "Delivery set for: " + request.pickupDate.toString();
// }

// Function to check the first available slot
function checkAvailable(TownDeliveryTable deliveryTable, string packageId) returns string {
    if (deliveryTable.Slot_1.toString() == "Available") {
        return "Slot_1";
    } else if (deliveryTable.Slot_2.toString() == "Available") {
        return "Slot_2";
    } else if (deliveryTable.Slot_3.toString() == "Available") {
        return "Slot_3";
    } else if (deliveryTable.Slot_4.toString() == "Available") {
        return "Slot_4";
    } else if (deliveryTable.Slot_5.toString() == "Available") {
        return "Slot_5";
    } else if (deliveryTable.Slot_6.toString() == "Available") {
        return "Slot_6";
    } else if (deliveryTable.Slot_7.toString() == "Available") {
        return "Slot_7";
    } else if (deliveryTable.Slot_8.toString() == "Available") {
        return "Slot_8";
    } else if (deliveryTable.Slot_9.toString() == "Available") {
        return "Slot_9";
    } else if (deliveryTable.Slot_10.toString() == "Available") {
        return "Slot_10";
    }
    return ""; // If no slot is available, return an empty string
}

// Main function to handle insertion/update of delivery table
function post_slot1(string packageId, string toTown, string deliveryDate) returns string|error {
    mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");
    sql:ParameterizedQuery updateQuery = `UPDATE Town_Delivery_table 
                                          SET Slot_1 = ${packageId} 
                                          WHERE Town = ${toTown} AND Date = ${deliveryDate};`;
    log:printInfo("Executing UPDATE query for Slot_1");
    sql:ExecutionResult|sql:Error updateResult = mysqlClient->execute(updateQuery);

    if (updateResult is sql:Error) {
        log:printError("Error executing update query for Slot_1", updateResult);
        return updateResult;
    }

    check mysqlClient.close();
    return "Slot_1 updated successfully.";
}

function post_slot2(string packageId, string toTown, string deliveryDate) returns string|error {
    mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");
    sql:ParameterizedQuery updateQuery = `UPDATE Town_Delivery_table 
                                          SET Slot_2 = ${packageId} 
                                          WHERE Town = ${toTown} AND Date = ${deliveryDate};`;
    log:printInfo("Executing UPDATE query for Slot_2");
    sql:ExecutionResult|sql:Error updateResult = mysqlClient->execute(updateQuery);

    if (updateResult is sql:Error) {
        log:printError("Error executing update query for Slot_2", updateResult);
        return updateResult;
    }

    check mysqlClient.close();
    return "Slot_2 updated successfully.";
}

function post_slot3(string packageId, string toTown, string deliveryDate) returns string|error {
    mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");
    sql:ParameterizedQuery updateQuery = `UPDATE Town_Delivery_table 
                                          SET Slot_3 = ${packageId} 
                                          WHERE Town = ${toTown} AND Date = ${deliveryDate};`;
    log:printInfo("Executing UPDATE query for Slot_3");
    sql:ExecutionResult|sql:Error updateResult = mysqlClient->execute(updateQuery);

    if (updateResult is sql:Error) {
        log:printError("Error executing update query for Slot_3", updateResult);
        return updateResult;
    }

    check mysqlClient.close();
    return "Slot_3 updated successfully.";
}

////////
function post_slot4(string packageId, string toTown, string deliveryDate) returns string|error {
    mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");
    sql:ParameterizedQuery updateQuery = `UPDATE Town_Delivery_table 
                                          SET Slot_4 = ${packageId} 
                                          WHERE Town = ${toTown} AND Date = ${deliveryDate};`;
    log:printInfo("Executing UPDATE query for Slot_4");
    sql:ExecutionResult|sql:Error updateResult = mysqlClient->execute(updateQuery);

    if (updateResult is sql:Error) {
        log:printError("Error executing update query for Slot_4", updateResult);
        return updateResult;
    }

    check mysqlClient.close();
    return "Slot_4 updated successfully.";
}

function post_slot5(string packageId, string toTown, string deliveryDate) returns string|error {
    mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");
    sql:ParameterizedQuery updateQuery = `UPDATE Town_Delivery_table 
                                          SET Slot_5 = ${packageId} 
                                          WHERE Town = ${toTown} AND Date = ${deliveryDate};`;
    log:printInfo("Executing UPDATE query for Slot_5");
    sql:ExecutionResult|sql:Error updateResult = mysqlClient->execute(updateQuery);

    if (updateResult is sql:Error) {
        log:printError("Error executing update query for Slot_5", updateResult);
        return updateResult;
    }

    check mysqlClient.close();
    return "Slot_5 updated successfully.";
}

function post_slot6(string packageId, string toTown, string deliveryDate) returns string|error {
    mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");
    sql:ParameterizedQuery updateQuery = `UPDATE Town_Delivery_table 
                                          SET Slot_6 = ${packageId} 
                                          WHERE Town = ${toTown} AND Date = ${deliveryDate};`;
    log:printInfo("Executing UPDATE query for Slot_6");
    sql:ExecutionResult|sql:Error updateResult = mysqlClient->execute(updateQuery);

    if (updateResult is sql:Error) {
        log:printError("Error executing update query for Slot_6", updateResult);
        return updateResult;
    }

    check mysqlClient.close();
    return "Slot_6 updated successfully.";
}

function post_slot7(string packageId, string toTown, string deliveryDate) returns string|error {
    mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");
    sql:ParameterizedQuery updateQuery = `UPDATE Town_Delivery_table 
                                          SET Slot_7 = ${packageId} 
                                          WHERE Town = ${toTown} AND Date = ${deliveryDate};`;
    log:printInfo("Executing UPDATE query for Slot_7");
    sql:ExecutionResult|sql:Error updateResult = mysqlClient->execute(updateQuery);

    if (updateResult is sql:Error) {
        log:printError("Error executing update query for Slot_7", updateResult);
        return updateResult;
    }

    check mysqlClient.close();
    return "Slot_7 updated successfully.";
}

function post_slot8(string packageId, string toTown, string deliveryDate) returns string|error {
    mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");
    sql:ParameterizedQuery updateQuery = `UPDATE Town_Delivery_table 
                                          SET Slot_8 = ${packageId} 
                                          WHERE Town = ${toTown} AND Date = ${deliveryDate};`;
    log:printInfo("Executing UPDATE query for Slot_8");
    sql:ExecutionResult|sql:Error updateResult = mysqlClient->execute(updateQuery);

    if (updateResult is sql:Error) {
        log:printError("Error executing update query for Slot_8", updateResult);
        return updateResult;
    }

    check mysqlClient.close();
    return "Slot_8 updated successfully.";
}

function post_slot9(string packageId, string toTown, string deliveryDate) returns string|error {
    mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");
    sql:ParameterizedQuery updateQuery = `UPDATE Town_Delivery_table 
                                          SET Slot_9 = ${packageId} 
                                          WHERE Town = ${toTown} AND Date = ${deliveryDate};`;
    log:printInfo("Executing UPDATE query for Slot_9");
    sql:ExecutionResult|sql:Error updateResult = mysqlClient->execute(updateQuery);

    if (updateResult is sql:Error) {
        log:printError("Error executing update query for Slot_9", updateResult);
        return updateResult;
    }

    check mysqlClient.close();
    return "Slot_9 updated successfully.";
}

function post_slot10(string packageId, string toTown, string deliveryDate) returns string|error {
    mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");
    sql:ParameterizedQuery updateQuery = `UPDATE Town_Delivery_table 
                                          SET Slot_10 = ${packageId} 
                                          WHERE Town = ${toTown} AND Date = ${deliveryDate};`;
    log:printInfo("Executing UPDATE query for Slot_10");
    sql:ExecutionResult|sql:Error updateResult = mysqlClient->execute(updateQuery);

    if (updateResult is sql:Error) {
        log:printError("Error executing update query for Slot_10", updateResult);
        return updateResult;
    }

    check mysqlClient.close();
    return "Slot_10 updated successfully.";
}

function insertIntoTownDeliveryTable(StandardDeliveryRequestData request, string packageId, string deliveryDate) returns string|error {
    mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");

    log:printInfo("Connecting to the database...");

    // Check if the row for the town and date already exists
    sql:ParameterizedQuery selectQuery = `SELECT * FROM Town_Delivery_table 
                                           WHERE Town = ${request.toTown} AND Date = ${deliveryDate};`;

    stream<TownDeliveryTable, sql:Error?> resultStream = mysqlClient->query(selectQuery);
    boolean rowExists = false;

    sql:Error? forEach = resultStream.forEach(function(TownDeliveryTable deliveryTable) {
        rowExists = true;

        // Get the first available slot
        string availableSlot = checkAvailable(deliveryTable, packageId);

        log:printInfo("Found available slot: " + availableSlot);

        string|error postResult;

        if (availableSlot == "Slot_1") {
            postResult = post_slot1(packageId, request.toTown, deliveryDate);
        } else if (availableSlot == "Slot_2") {
            postResult = post_slot2(packageId, request.toTown, deliveryDate);
        } else if (availableSlot == "Slot_3") {
            postResult = post_slot3(packageId, request.toTown, deliveryDate);
        } else if (availableSlot == "Slot_4") {
            postResult = post_slot4(packageId, request.toTown, deliveryDate);
        } else if (availableSlot == "Slot_5") {
            postResult = post_slot5(packageId, request.toTown, deliveryDate);
        } else if (availableSlot == "Slot_6") {
            postResult = post_slot6(packageId, request.toTown, deliveryDate);
        } else if (availableSlot == "Slot_7") {
            postResult = post_slot7(packageId, request.toTown, deliveryDate);
        } else if (availableSlot == "Slot_8") {
            postResult = post_slot8(packageId, request.toTown, deliveryDate);
        } else if (availableSlot == "Slot_9") {
            postResult = post_slot9(packageId, request.toTown, deliveryDate);
        } else if (availableSlot == "Slot_10") {
            postResult = post_slot10(packageId, request.toTown, deliveryDate);
        } else {
            // Handle case when no slots are available
            log:printError("No available slots for the given date and town.");
            postResult = error("No available slots.");
        }

    });

    if (!rowExists) {
        log:printInfo("Row does not exist. Inserting new row for Slot 1.");
        sql:ParameterizedQuery insertQuery = `INSERT INTO Town_Delivery_table 
                                          (Town, Date, Slot_1, Slot_2, Slot_3, Slot_4, Slot_5, Slot_6, Slot_7, Slot_8, Slot_9, Slot_10) 
                                          VALUES (${request.toTown}, ${deliveryDate}, ${packageId}, 
                                                  "Available", "Available", "Available", "Available", "Available", 
                                                  "Available", "Available", "Available", "Available");`;

        sql:ExecutionResult|sql:Error insertResult = mysqlClient->execute(insertQuery);
        if (insertResult is sql:Error) {
            log:printError("Error inserting new row", insertResult);
            return insertResult;
        }
    }

    check mysqlClient.close();
    return "Delivery set successfully.";
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
    string|error insertIntoTownDeliveryTableResult = insertIntoTownDeliveryTable(request, packageId, deliveryDate);

    // Send the complete response message to the Kafka testrep topic
    check StandardDeliveryReplyProducer->send({
        topic: "StandardDeliveryReply",
        value: packageId.toString()
    });

    log:printInfo("Successfully sent package id to StandardDeliveryReply topic.");

    return "insertIntoRequestTable package : " + packageId.toString();
}

//pick up stuff

