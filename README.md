# DSA_ASS2_2024
Containerized Microservices with Ballerina and Kafka for Course Title: Distributed Systems and Applications   Course Code: DSA612S   Assessment: Second Assignment 

![alt text](image.png)

## How to create the db for local dev, and other info
### Do NoT edit the kafka folder properties !!

### **Logistics Admin Service**:

- Handles package delivery requests,
- Dispatches them to specialized delivery services (Standard, Express, International),
- Detects conflicts (e.g., time or capacity issues),
- Coordinates pickup and delivery schedules across services.

### **Specialized Delivery Services**:

- **Standard Delivery**: Handles regular shipments deliver after 2pm. slot 6 - 10
- **Express Delivery**: Handles expedited shipments with higher priority and shorter delivery times delivers before 2. slot 1- 5
- **International Delivery**: Manages cross-border shipments, handling customs and multiple delivery partners. normal time from and to town plus 30 days
- Each service checks delivery availability, reports any scheduling conflicts, and proposes alternative delivery times if needed.

### **Kafka Topics**:

- Used for asynchronous communication between the **Logistics Admin Service** and specialized delivery services.

### **Databases**:

- Store information such as:
    - Customer data (name, contact info),
    - Delivery schedules (pickup and drop-off times),
    - Delivery status and tracking information.

### **Docker**:

- Used to containerize and deploy each service:
    - **Logistics Admin Service**,
    - **Standard Delivery Service**,
    - **Express Delivery Service**,
    - **International Delivery Service**.

start Zookeeper 

`./zookeeper-server-start.sh ../config/zookeeper.properties`

start kafka server

`./kafka-server-start.sh ../config/server.properties`

create a new topic 

`topic` with 3 partitions and a replication factor of 1 when my Kafka broker is running at `localhost:9092`

`./kafka-topics.sh --bootstrap-server localhost:9092 --topic first_topic --create --partitions 3 --replication-factor 1` 

produce a message

`./kafka-console-producer.sh --topic test --bootstrap-server localhost:9092`

 describe a Kafka topic

`./kafka-topics.sh --bootstrap-server localhost:9092 --describe --topic first_topic`

Delete a Kafka Topic

`./kafka-topics.sh --bootstrap-server localhost:9092 --delete --topic first_topic`

Produce a Message into a Kafka Topic using the CLI

`./kafka-console-producer.sh --bootstrap-server localhost:9092 --topic first_topic`

`.After the producer is opened, you should see a > sign. Then any line of text you write afterwards will be sent to the Kafka topic (when pressing Enter)`

Consume Data in a Kafka Topic using the CLI

`./kafka-console-consumer.sh --bootstrap-server localhost:9092 --topic first_topic --from-beginning`

topics

- `LogisticsAvailibilityRequest`
- `LogisticsAvailibilityReply`

might not use the ones above this 

- `StandardDeliveryRequest`
- `StandardDeliveryReply`
- 
- `ExpressDeliveryRequest`
- `ExpressDeliveryReply`
- 
- `InternationalDeliveryRequest`
- `InternationalDeliveryResponse`

codes to recreate 

run this to create the Db in cli that logs in as the user RXD

mysql -u RXD -p 

### Create a New User if you dont have the user  {because the code is told to use this login info }

If you want to create a new MySQL user who will have access to this database:

make the password “100101”

```sql
CREATE USER 'new_user'@'localhost' IDENTIFIED BY 'user_password';

```

### Grant Permissions to the New User

Give the newly created user all the privileges on the newly created database:

```sql
GRANT ALL PRIVILEGES ON new_database_name.* TO 'new_user'@'localhost';

```

### Full Example:

```sql
sql
Copy code
CREATE DATABASE LogisticsDB;
CREATE USER 'logistics_user'@'localhost' IDENTIFIED BY 'logistics_pass';
GRANT ALL PRIVILEGES ON LogisticsDB.* TO 'logistics_user'@'localhost';
FLUSH PRIVILEGES;

```

### databse setup:

```sql
CREATE TABLE `routing_table` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `From_Location` varchar(255) NOT NULL,
  `To_Location` varchar(255) DEFAULT NULL,
  `Distance` varchar(255) DEFAULT NULL,
  `Travel_Time` varchar(255) DEFAULT NULL,
  `Type` varchar(255) DEFAULT NULL,
  PRIMARY KEY (`id`)
) ENGINE = InnoDB DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci;

```

```sql
INSERT INTO `Town_Delivery_table` 
(`Town`, `Date`, `Slot_1`, `Slot_2`, `Slot_3`, `Slot_4`, `Slot_5`, `Slot_6`, `Slot_7`, `Slot_8`, `Slot_9`, `Slot_10`)
VALUES
('Windhoek', '2024-10-01', 'PackageID-001', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available'),
('Windhoek', '2024-10-02', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available'),
('Mariental', '2024-10-01', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available'),
('Okahandja', '2024-10-01', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available'),
('Swakopmund', '2024-10-01', 'Available', 'Available', 'Available', 'PackageID-002', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available'),
('Walvis Bay', '2024-10-01', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available'),
('Lüderitz', '2024-10-01', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available'),
('Oranjemund', '2024-10-01', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available'),
('Karasburg', '2024-10-01', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available'),
('Oshikango', '2024-10-01', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available'),
('Keetmanshoop', '2024-10-01', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available', 'Available');

```
make two tables the  Town_Delivery_table, and  Town_Pickup_table just change name in command

```sql
CREATE TABLE
  `Town_Delivery_table` (
    `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `Town` varchar(255) NOT NULL,
    `Date` varchar(255) DEFAULT NULL,
    `Slot_1` varchar(255) DEFAULT NULL,
    `Slot_2` varchar(255) DEFAULT NULL,
    `Slot_3` varchar(255) DEFAULT NULL,
    `Slot_4` varchar(255) DEFAULT NULL,
    `Slot_5` varchar(255) DEFAULT NULL,
    `Slot_6` varchar(255) DEFAULT NULL,
    `Slot_7` varchar(255) DEFAULT NULL,
    `Slot_8` varchar(255) DEFAULT NULL,
    `Slot_9` varchar(255) DEFAULT NULL,
    `Slot_10` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`id`)
  ) ENGINE = InnoDB AUTO_INCREMENT = 12 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci
```

```sql
CREATE TABLE
  `request_table` (
    `Request_ID` int(10) unsigned NOT NULL AUTO_INCREMENT,
    `Customer_Name` varchar(255) NOT NULL,
    `Customer contact` varchar(255) NOT NULL,
    `From Town` varchar(255) NOT NULL,
    `To Town` varchar(255) NOT NULL,
    `Pickup Date` varchar(255) DEFAULT NULL,
    `Pickup Slot` varchar(255) DEFAULT NULL,
    `Delivery Type` varchar(255) DEFAULT NULL,
    `Delivery Date` varchar(255) DEFAULT NULL,
    `Package ID` varchar(255) DEFAULT NULL,
    PRIMARY KEY (`Request_ID`)
  ) ENGINE = InnoDB AUTO_INCREMENT = 3 DEFAULT CHARSET = utf8mb4 COLLATE = utf8mb4_unicode_ci

```
