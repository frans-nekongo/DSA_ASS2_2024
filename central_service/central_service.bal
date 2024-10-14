// AUTO-GENERATED FILE.
// This file is auto-generated by the Ballerina OpenAPI tool.

import ballerina/http;
import ballerina/log;
import ballerina/sql;
// import ballerina/uuid;
import ballerinax/kafka;
import ballerinax/mysql;
import ballerinax/mysql.driver as _;

// listener http:Listener ep0 = new (9090, config = {host: "localhost"});
listener http:Listener ep0 = new (9090, config = {host: "0.0.0.0"});

// Database configuration
string dbUser = "RXD";
string dbPassword = "100101";

public type inline_response_200 record {
    # Indicates if the specified slot is available.
    boolean available?;
    # The name of the town.
    string townName?;
    # The date for which availability is checked.
    string date?;
    # The time slot being checked for availability.
    string slot?;
};

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

public type PackageId record {
    string id; // The package ID
};

public type request_table record {
    // Unique ID for the delivery request
    string request_id; // Assuming there's a unique identifier for each request
    // Name of the customer
    string customer_name; // Customer's name
    // Contact information of the customer
    string customer_contact; // Customer's contact information
    // Town where the package will be picked up
    string from_town; // Pickup town
    // Town where the package will be delivered
    string to_town; // Delivery town
    // Date for the package pickup
    string pickup_date; // Date for pickup
    // The time slot for the pickup
    string pickup_slot; // Slot for pickup
    // Type of delivery requested
    string delivery_type; // Delivery type (Normal, Express, International)
    // Estimated date for the delivery
    string delivery_date; // Estimated delivery date

};
// Service-level CORS configuration
@http:ServiceConfig {
    cors: {
        allowOrigins: ["*"], // Allow all origins or specify your allowed origins
        allowCredentials: false,
        allowHeaders: ["Content-Type", "Authorization"],
        exposeHeaders: ["X-Custom-Header"],
        maxAge: 3600
    }
}
service / on ep0 {
    resource function options memo() returns http:Response {
        // Create a response object with status code 204 and appropriate CORS headers
        http:Response response = new;

        response.statusCode = 204; // No Content
        response.reasonPhrase = "No Content";

        // Add CORS headers using appropriate methods
        response.addHeader("Access-Control-Allow-Origin", "*"); // or specify allowed origins
        response.addHeader("Access-Control-Allow-Methods", "GET, POST, PUT, OPTIONS");
        response.addHeader("Access-Control-Allow-Headers", "Content-Type, Authorization");
        response.addHeader("Access-Control-Max-Age", "3600");

        return response;
    }
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
    resource function get availabilityCheck(string date, string town, int slot) returns inline_response_200|error {
        mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");

        log:printInfo("Connecting to the database...");

        // Check if the row for the town and date already exists
        sql:ParameterizedQuery selectQuery = `SELECT * FROM Town_Pickup_table 
                                           WHERE Town = ${town} AND Date = ${date};`;

        stream<TownDeliveryTable, sql:Error?> resultStream = mysqlClient->query(selectQuery);
        boolean rowExists = false;
        string[] availableSlots = [];

        sql:Error? forEach = resultStream.forEach(function(TownDeliveryTable deliveryTable) {
            rowExists = true;

            // Get all available slots
            availableSlots = checkAvailable(deliveryTable);

            log:printInfo("Found available slots: " + availableSlots.toString());
        });

        if (!rowExists) {
            log:printInfo("Row does not exist. Inserting new row with all slots available.");
            sql:ParameterizedQuery insertQuery = `INSERT INTO Town_Pickup_table 
                                          (Town, Date, Slot_1, Slot_2, Slot_3, Slot_4, Slot_5, Slot_6, Slot_7, Slot_8, Slot_9, Slot_10) 
                                          VALUES (${town}, ${date}, "Available", 
                                                  "Available", "Available", "Available", "Available", "Available", 
                                                  "Available", "Available", "Available", "Available");`;

            sql:ExecutionResult|sql:Error insertResult = mysqlClient->execute(insertQuery);

            if (insertResult is sql:Error) {
                log:printError("Error inserting new row", insertResult);
                return insertResult;
            }

            // If the row was inserted, consider all slots available
            availableSlots = ["Slot_1", "Slot_2", "Slot_3", "Slot_4", "Slot_5", "Slot_6", "Slot_7", "Slot_8", "Slot_9", "Slot_10"];
        }

        // Convert the incoming `slot` integer into the format like "Slot_1", "Slot_2", etc.
        string requestedSlot = "Slot_" + slot.toString();

        // Check if the requested slot is available
        boolean slotFound = false;
        // Ensure the loop variable is defined with the correct type
        foreach string availableSlot in availableSlots {
            if (availableSlot == requestedSlot) {
                slotFound = true;
                break;
            }
        }

        // Prepare and return the response based on slot availability
        inline_response_200 response;
        if (slotFound) {
            response = {
                available: true,
                townName: town,
                date: date,
                slot: requestedSlot
            };
        } else {
            response = {
                available: false,
                townName: town,
                date: date,
                slot: requestedSlot
            };
        }

        // Close the database connection and return the response
        check mysqlClient.close();
        return response;
    }

    // # Retrieve package status by package ID.
    // #
    // # + return - Package information retrieved successfully. 
    resource function get packageStatus(string packageId) returns inline_response_200_1|error {
        // Create a MySQL client to connect to the database
        mysql:Client mysqlClient = check new ("localhost", dbUser, dbPassword, database = "LogisticsDB");

        log:printInfo("Connecting to the database...");

        // Prepare the SQL query to fetch the details of the package based on the Package_ID
        sql:ParameterizedQuery selectQuery = `SELECT * FROM request_table 
                                           WHERE Package_ID = ${packageId};`;

        // Execute the query and get the result stream
        stream<request_table, sql:Error?> resultStream = mysqlClient->query(selectQuery);
        boolean rowExists = false;

        // Declare a variable to hold the response data
        inline_response_200_1 response = {}; // Initialize response to an empty record

        // Variable to track if there's an error
        boolean errorOccurred = false;
        string errorMessage = "";

        // Process the results from the database
        sql:Error? forEach = resultStream.forEach(function(request_table request) {
            rowExists = true;

            // Ensure deliveryType is a valid type
            string deliveryTypeValue = request.delivery_type;
            if (deliveryTypeValue == "Normal" || deliveryTypeValue == "Express" || deliveryTypeValue == "International") {
                // Populate the response record with details from the request
                response = {
                    requestId: request.request_id, // Assuming you have a field `request_id` in your table
                    customerName: request.customer_name,
                    customerContact: request.customer_contact,
                    fromTown: request.from_town,
                    toTown: request.to_town,
                    pickupDate: request.pickup_date,
                    pickupSlot: request.pickup_slot,
                    deliveryType: <"Normal"|"Express"|"International">deliveryTypeValue, // Type assertion
                    deliveryDate: request.delivery_date // Assuming you have a field `delivery_date`
                };

                log:printInfo("Found package details: " + response.toString());
            } else {
                log:printError("Invalid delivery type found in database: " + deliveryTypeValue);
                errorOccurred = true; // Mark that an error occurred
                errorMessage = "Invalid delivery type found for Package ID: " + packageId; // Store error message
            }
        });

        // Check if no rows were found
        if (!rowExists) {
            log:printInfo("No package found with ID: " + packageId);
            return error("No package found with the provided Package ID.");
        }

        // Check if an error occurred during processing
        if (errorOccurred) {
            return error(errorMessage); // Return the accumulated error message
        }

        // Close the database connection
        check mysqlClient.close();

        // Return the response
        return response; // Now guaranteed to be initialized
    }

    // # Submit a delivery request.
    // #
    // # + return - Delivery request successfully created. 
    resource function post request(@http:Payload DeliveryRequest payload) returns inline_response_201|error {
        // Log the raw data of the payload to see what it looks like
        log:printInfo("Received Request Payload: " + payload.toString());

        // Extract and log the delivery type
        string deliveryType = payload.deliveryType is string ? <string>payload.deliveryType : "";
        log:printInfo("Delivery Type: " + deliveryType);

        // // Simulate generating a package ID
        // string packageId = "PackageID-" + uuid:createType1AsString();
        // log:printInfo("Generated Package ID: " + packageId);

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
            packageId: ""
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

        // Consumer for getting the generated package ID from _______DeliveryReply,changed from multiple response points to one, since its a response doesnt matter all look the same
        kafka:Consumer StandardDeliveryReply = check new (kafka:DEFAULT_URL, {
            groupId: "StandardDeliveryReplyGroup", // Define the group for the consumer
            topics: "StandardDeliveryReply" // Subscribe to the StandardDeliveryReply topic
        });

        // Poll for incoming messages (raw strings)
        string[] incomingMessages = check StandardDeliveryReply->pollPayload(15);

        // Log the number of messages received
        log:printInfo("Number of messages received: " + incomingMessages.length().toString());

        // Check if any messages were received
        if (incomingMessages.length() > 0) {
            // Log the first message received
            log:printInfo("Received message: " + incomingMessages[0]);

            // Extract package ID from the first message
            string packageId = incomingMessages[0]; // Assuming the message format is simply the package ID

            // Return the package ID as the response
            return {
                packageId: packageId // Return the package ID
            };
        } else {
            log:printInfo("No message received.");

            return {
                packageId: "No package ID received"
            };
        }

    }

}

function checkAvailable(TownDeliveryTable deliveryTable) returns string[] {
    string[] availableSlots = [];

    if (deliveryTable.Slot_1.toString() == "Available") {
        availableSlots.push("Slot_1");
    }
    if (deliveryTable.Slot_2.toString() == "Available") {
        availableSlots.push("Slot_2");
    }
    if (deliveryTable.Slot_3.toString() == "Available") {
        availableSlots.push("Slot_3");
    }
    if (deliveryTable.Slot_4.toString() == "Available") {
        availableSlots.push("Slot_4");
    }
    if (deliveryTable.Slot_5.toString() == "Available") {
        availableSlots.push("Slot_5");
    }
    if (deliveryTable.Slot_6.toString() == "Available") {
        availableSlots.push("Slot_6");
    }
    if (deliveryTable.Slot_7.toString() == "Available") {
        availableSlots.push("Slot_7");
    }
    if (deliveryTable.Slot_8.toString() == "Available") {
        availableSlots.push("Slot_8");
    }
    if (deliveryTable.Slot_9.toString() == "Available") {
        availableSlots.push("Slot_9");
    }
    if (deliveryTable.Slot_10.toString() == "Available") {
        availableSlots.push("Slot_10");
    }

    return availableSlots; // Returns an array of available slots
}

