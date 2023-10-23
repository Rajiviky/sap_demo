# Build stage

FROM golang:latest AS base

LABEL maintainer = "rajiviky2309@gmail.com"

RUN mkdir -p src/inputapp
WORKDIR /src/inputapp

COPY . ./

RUN CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -a -o /app .

# Last stage 

FROM alpine:latest

COPY --from=base /app ./

RUN chmod +x ./app

RUN apk --no-cache add curl

ENTRYPOINT [ "./app" ]

EXPOSE 3000


