package personal.specific;

import com.example.Customer;
import org.apache.kafka.clients.producer.KafkaProducer;
import org.apache.kafka.clients.producer.ProducerRecord;

import java.io.FileInputStream;
import java.io.IOException;
import java.io.InputStream;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.util.Properties;

public class Producer {

    public static void main(String[] args) {
        try {
            // Load Kafka producer properties
            final Properties props = loadConfig("/my-general-cflt-repo/avro_producer_consumer/prod/src/main/java/personal/resources/client.properties");

            String topic = "customer-avro";

            KafkaProducer<String, Customer> producer = new KafkaProducer<>(props);

            for (int i = 0; i < 10; i++) {
                Customer customer = Customer.newBuilder()
                        .setAge(25 + i)  // Vary age for each record
                        .setAutomatedEmail(i % 2 == 0)  // Alternate automated email
                        .setFirstName("FirstName" + i)
                        .setLastName("LastName" + i)
                        .setHeight(160f + i)  // Vary height
                        .setWeight(60f + i)  // Vary weight
                        .build();

                ProducerRecord<String, Customer> producerRecord = new ProducerRecord<>(topic, customer);

                System.out.println("Sending customer record #" + i);
                producer.send(producerRecord, (metadata, exception) -> {
                    if (exception == null) {
                        System.out.println("Record sent successfully: " + metadata);
                    } else {
                        exception.printStackTrace();
                    }
                });
            }

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
