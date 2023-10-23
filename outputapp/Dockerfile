# Build stage

FROM golang:latest AS base

LABEL maintainer = "rajiviky2309@gmail.com"

RUN mkdir -p src/outputapp

WORKDIR /src/outputapp

COPY . ./


RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o /app .

# Last stage 

FROM alpine:latest

COPY --from=base /app ./

RUN chmod +x ./app

ENTRYPOINT [ "./app" ]

EXPOSE 5000


