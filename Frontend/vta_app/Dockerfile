# Build stage
FROM ghcr.io/cirruslabs/flutter:3.24.3 AS build
WORKDIR /app

# Copy pubspec files and get dependencies
COPY pubspec.yaml pubspec.lock ./
RUN flutter pub get

# Copy the rest of the application
COPY . .

# Build web application
RUN flutter build web --release

# Runtime stage - use nginx to serve the Flutter web app
FROM nginx:alpine
WORKDIR /usr/share/nginx/html

# Remove default nginx static assets
RUN rm -rf ./*

# Copy built Flutter web app
COPY --from=build /app/build/web .

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80

CMD ["nginx", "-g", "daemon off;"]
