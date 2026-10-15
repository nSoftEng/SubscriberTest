# Builder stage: compile native-extension gems (e.g. json) with build-essential
FROM ruby:4.0.7-slim AS builder

WORKDIR /app

RUN apt-get update && \
    apt-get install -y --no-install-recommends build-essential && \
    rm -rf /var/lib/apt/lists/*

COPY Gemfile Gemfile.lock ./
RUN bundle install

# Final stage: slim image, no compiler, just the installed gems
FROM ruby:4.0.7-slim

WORKDIR /app

COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy application code
COPY . .

# Make main.rb executable
RUN chmod +x main.rb

# Default command shows usage
CMD ["ruby", "main.rb"]
