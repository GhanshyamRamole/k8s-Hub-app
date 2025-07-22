 # Use an official Node.js runtime as a base image for the build stage
FROM node:18-alpine AS build-stage
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./
# Install dependencies
RUN yarn install

# Copy the rest of the application code
COPY . .

# Build the React app
RUN npm run build

# Use an official Nginx runtime as a base image for the production stage
FROM nginx:latest
# Copy the Nginx configuration file
COPY nginx.conf /etc/nginx/conf.d/default.conf
# Copy the build artifacts from the build stage
COPY --from=build-stage /app/build/ /usr/share/nginx/html
# Expose port 80
EXPOSE 80
# Start Nginx
CMD ["nginx", "-g", "daemon off;"]
