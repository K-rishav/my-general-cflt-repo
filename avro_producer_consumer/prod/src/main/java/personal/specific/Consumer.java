package personal.specific;

import com.example.Customer;

import org.apache.kafka.clients.consumer.ConsumerConfig;
import org.apache.kafka.clients.consumer.ConsumerRecord;
import org.apache.kafka.clients.consumer.ConsumerRecords;
import org.apache.kafka.clients.consumer.KafkaConsumer;

import java.io.*;
import java.nio.file.*;
import java.time.Duration;
import java.util.*;

public class Consumer {

    public static void main(String[] args) {
        try {
            // Add the path to your properties file here
            final Properties props = loadConfig("/my-general-cflt-repo/avro_producer_consumer/prod/src/main/java/personal/resources/client.properties");
            props.put(ConsumerConfig.GROUP_ID_CONFIG, "json-schema-test");
            props.put(ConsumerConfig.AUTO_OFFSET_RESET_CONFIG, "earliest");

            String topic = "customer-avro";

            KafkaConsumer<String, Customer> kafkaConsumer = new KafkaConsumer<>(props);
            kafkaConsumer.subscribe(Collections.singleton(topic));

            System.out.println("Waiting for data...");

            while (true){
                System.out.println("Polling");
                ConsumerRecords<String, Customer> records = kafkaConsumer.poll(Duration.ofMillis(1000));

                for (ConsumerRecord<String, Customer> record : records){
                       System.out.printf("Key => %s | Value => %s%n", record.key(), record.value());
                }
            }

        } catch (IOException e) {
            e.printStackTrace();
        }
    }

    public static Properties loadConfig(String configFile) throws IOException {
        if (!Files.exists(Paths.get(configFile))) {
            throw new IOException(configFile + " not found.");
        }
        Properties cfg = new Properties();
        try (InputStream inputStream = new FileInputStream(configFile)) {
            cfg.load(inputStream);
        }
        return cfg;
    }
}
