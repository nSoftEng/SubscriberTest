# Use official Ruby image with latest stable version
FROM ruby:4.0.7

# Set working directory
WORKDIR /app

# Copy Gemfile for dependencies
COPY Gemfile ./

# Install bundler and dependencies
RUN bundle install

# Copy application code
COPY . .

# Make main.rb executable
RUN chmod +x main.rb

# Default command shows usage
CMD ["ruby", "main.rb"]
