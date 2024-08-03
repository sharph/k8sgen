FROM node:18

WORKDIR /app
COPY . .
RUN npm ci
RUN npm run build

EXPOSE 3000

CMD ["node", "build"]
