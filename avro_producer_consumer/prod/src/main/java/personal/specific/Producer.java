package personal.specific;

import com.example.Customer;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;
import java.io.*;
import java.nio.file.*;
import java.util.*;

public class Producer {

    public static void main(String[] args) {
        try {
            Customer customer = Customer.newBuilder()
                .setAge(34)
                .setAutomatedEmail(false)
                .setFirstName("Vijay")
                .setLastName("Roy")
                .setHeight(178f)
                .setWeight(75f)
                .build();

            // Add the path to your properties file here
            final Properties props = loadConfig("/Users/rikumar/Development/java/prod/src/main/java/personal/resources/client.properties");

            String topic = "customer-avro";

            KafkaProducer<String, Customer> producer = new KafkaProducer<>(props);

            // Create a topic in Confluent cloud UI before running this program.
            // Use the created topic name here
            ProducerRecord<String, Customer> producerRecord = new ProducerRecord<>(topic, customer);

            System.out.println(customer);
            producer.send(producerRecord, (metadata, exception) -> {
                if (exception == null) {
                    System.out.println(metadata);
                } else {
                    exception.printStackTrace();
                }
            });

            producer.flush();
            producer.close();
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
