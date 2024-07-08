# Stage 1: Build the React application
FROM node:20 as build

# Set the working directory
WORKDIR /app

# Copy package.json and package-lock.json to leverage Docker cache
COPY package.json package-lock.json ./

# Install dependencies
RUN npm install

# Copy the rest of the application code
COPY . /app

# Build the application
RUN npm run build

# Stage 2: Serve the static files with Nginx
FROM nginx:alpine

# Copy the build output to the Nginx html directory
COPY --from=build /app/dist /usr/share/nginx/html

# Expose the port Nginx will serve on
EXPOSE 80

# Command to run Nginx
CMD ["nginx", "-g", "daemon off;"]
