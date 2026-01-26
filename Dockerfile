FROM node:19-alpine

RUN apk add --no-cache bash curl

WORKDIR /app

COPY package.json ./

RUN npm install

COPY . .

EXPOSE 3000

ENTRYPOINT [ "./start.sh" ]
