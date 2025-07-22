 # Use an official Node.js runtime as a base image for the build stage
FROM node:18-alpine 

# workspace dir
WORKDIR /app

# Copy package.json and package-lock.json
COPY package*.json ./

# Install dependencies
RUN npm install --legacy-peer-deps
RUN npm install -g next

# Copy the rest of the application code
COPY . .

# Build the React app
RUN  npm run build

# Expose port 
EXPOSE 3000

# Start Nginx
CMD ["npm", "run", "dev"]
