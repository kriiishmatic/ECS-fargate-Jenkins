FROM maven:3.9.11 AS build
WORKDIR /app
COPY *.xml .
COPY src ./src
RUN mvn clean package
RUN mv target/shipping-1.0.jar shipping.jar

FROM eclipse-temurin:17-jre
WORKDIR /app
RUN addgroup roboshop && useradd -g roboshop roboshop && \
    chown -R roboshop:roboshop /app
# ENV CART_ENDPOINT=cart:8080 \
#     DB_HOST=mysql
LABEL project="roboshop" \
      author="krishna" \
      component="shipping"
EXPOSE 8080
COPY --from=build --chown=roboshop:roboshop /app/shipping.jar /app/shipping.jar
USER roboshop
CMD ["shipping.jar"]
ENTRYPOINT ["java", "-jar"]


# best practice observe another base os on stage 2 of build 

# FROM maven:3.9.11 AS builder
# WORKDIR /opt/server
# COPY pom.xml .
# COPY src ./src
# RUN mvn clean package && \
#     mv target/shipping-1.0.jar shipping.jar


# FROM eclipse-temurin:17-jre-alpine
# EXPOSE 8080
# RUN addgroup -S roboshop && adduser -S roboshop -G roboshop
# WORKDIR /opt/server
# ENV CART_ENDPOINT="cart:8080" \
#     DB_HOST="mysql"
# COPY --from=builder --chown=roboshop:roboshop /opt/server/shipping.jar .
# USER roboshop
# ENTRYPOINT ["sh", "-c", "sleep 30 && java -jar shipping.jar"]