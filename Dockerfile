# Use Elixir 1.17 to match Railway's environment
FROM elixir:1.17-alpine

# Install build dependencies
RUN apk add --no-cache build-base git

# Set working directory
WORKDIR /app

# Install hex + rebar
RUN mix local.hex --force && \
    mix local.rebar --force

# Copy mix files first for better caching
COPY mix.exs mix.lock ./

# Set environment variables
ENV MIX_ENV=prod
ENV PORT=8080

# Install dependencies
RUN mix deps.get --only prod
RUN mix deps.compile

# Copy application code
COPY . .

# Compile the application
RUN MIX_ENV=prod mix compile

# Expose port
EXPOSE 8080

# Start the application
CMD ["mix", "run", "--no-halt"]
