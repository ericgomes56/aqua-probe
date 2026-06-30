FROM centos:7.9.2009

# Copy the repo.txt file to the container.
COPY repo.txt /tmp/repo.txt

# Empty the original CentOS-Base.repo file and echo the contents from repo.txt into it
RUN > /etc/yum.repos.d/CentOS-Base.repo && \
    cat /tmp/repo.txt > /etc/yum.repos.d/CentOS-Base.repo && \
    rm -f /tmp/repo.txt

# Install dependencies (git, wget, tar, gcc, make, nc)
RUN yum install -y git wget tar gcc make nc

# Install Go (latest stable version from the official Go website)
RUN wget https://go.dev/dl/go1.21.4.linux-amd64.tar.gz && \
    tar -C /usr/local -xzf go1.21.4.linux-amd64.tar.gz && \
    rm -f go1.21.4.linux-amd64.tar.gz

# Set Go environment variables
ENV PATH="/usr/local/go/bin:${PATH}"

# Clone the memrun repository
RUN git clone https://github.com/guitmz/memrun.git /tmp/memrun

# Install Go dependencies and build the project
WORKDIR /tmp/memrun
RUN go build memrun.go

# Return to root directory
WORKDIR /

# Move the built memrun binary to /tmp folder
RUN mv /tmp/memrun/memrun /tmp/memrun.bin

# Remove the cloned repository to reduce image size
RUN rm -rf /tmp/memrun

# Rename memrun binary
RUN mv /tmp/memrun.bin /tmp/memrun

# Give memrun execution permission
RUN chmod +x /tmp/memrun

# Copy the target.c file to /tmp folder inside the container
COPY target.c /tmp/target.c

# Compile target.c into the target binary
RUN gcc /tmp/target.c -o /tmp/target

# Remove the target.c file to clean up
RUN rm -f /tmp/target.c

# Clean up yum cache to reduce image size
RUN yum clean all
