FROM debian:stable-slim as base

RUN apt-get update && \
    apt-get install --no-install-recommends -y build-essential ca-certificates  && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists

FROM base as clingo

RUN apt-get update && \
    apt-get install --no-install-recommends -y git cmake bison re2c && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists

RUN mkdir /opt/clingo-src && \
    mkdir /opt/clingo-build && \
    mkdir /opt/clingo
RUN git clone https://github.com/potassco/clingo.git --recursive --depth 1 /opt/clingo-src

WORKDIR /opt/clingo-src
RUN cmake -H/opt/clingo-src -B/opt/clingo-build -DCMAKE_BUILD_TYPE=release -DCMAKE_INSTALL_PREFIX=/opt/clingo && \
    cmake --build /opt/clingo-build && \
    cmake --build /opt/clingo-build --target install

FROM fpco/stack-build:latest as stack

WORKDIR /opt/steffensort
COPY backend/package.yaml .
COPY backend/stack.yaml .
RUN stack build --only-dependencies

COPY backend/ .
RUN stack install --local-bin-path /opt/steffensort

FROM debian:sid-slim as run

RUN apt-get update && \
    apt-get install --no-install-recommends -y libmysqlclient20 && \
    apt-get clean && \
    rm -rf /var/lib/lists

COPY --from=clingo /opt/clingo /opt/clingo
COPY --from=stack /opt/steffensort/steffensort /opt/steffensort

ENV PATH $PATH:/opt/clingo/bin:/opt/steffensort/

WORKDIR /opt/steffensort/
COPY backend/static static
COPY backend/config config

EXPOSE 3000
CMD sleep 10 && /opt/steffensort/steffensort
