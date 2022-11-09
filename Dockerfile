FROM archlinux:latest

# Install dependencies
RUN pacman --needed --noconfirm -Syu \
    base \
    base-devel \
    git \
    pacman-contrib \
    openssh

# Create non-root user
RUN useradd -m builder && \
    echo "builder ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    echo "%wheel ALL=(ALL:ALL) NOPASSWD: ALL" >> /etc/sudoers && \
    usermod -a -G wheel builder



# Make ssh directory for non-root user and add known_hosts
RUN mkdir -p /home/builder/.ssh && \
    touch /home/builder/.ssh/known_hosts

# Copy ssh_config
COPY ssh_config /home/builder/.ssh/config

# Set permissions
RUN chown -R builder:builder /home/builder/.ssh && \
    chmod 600 /home/builder/.ssh/* -R

COPY LICENSE README.md cred-helper.sh /

COPY entrypoint.sh /entrypoint.sh

# Switch to non-root user and set workdir
USER builder
WORKDIR /home/builder

ENTRYPOINT ["/entrypoint.sh"]
