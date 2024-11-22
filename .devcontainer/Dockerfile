ARG MAVEN_DOCKER_IMAGE="maven:3.9.9-eclipse-temurin-22-alpine"
ARG AWSGLUE_DOCKER_IMAGE="public.ecr.aws/glue/aws-glue-libs:glue_libs_4.0.0_image_01"
ARG AMAZONLINUX_DOCKER_IMAGE="public.ecr.aws/amazonlinux/amazonlinux:2023"

ARG AWSGLUE_LIBS_SSO_REPO="https://github.com/jerdoe/glue_libs_sso.git"
ARG AWSGLUE_LIBS_SSO_BRANCH="v1.0.8"
ARG AWSGLUE_LIBS_SSO_PATH="/tmp/glue_libs_sso"

ARG GLUE_USER="glue_user"
ARG GLUE_HOME="/home/${GLUE_USER}"
ARG GLUE_LIBS_DIR="${GLUE_HOME}/aws-glue-libs/jars"
ARG GLUE_CHOWN="${GLUE_USER}:root"

##############################
#### STAGE: build-jar-sso ####
##############################

FROM ${MAVEN_DOCKER_IMAGE} AS build-jar-sso

# Consume build arguments in this build stage
# (global scope build arguments are not automatically inherited into the build stages)
ARG AWSGLUE_LIBS_SSO_REPO
ARG AWSGLUE_LIBS_SSO_BRANCH
ARG AWSGLUE_LIBS_SSO_PATH

WORKDIR /project

RUN apk add git

RUN git clone --depth 1 --branch ${AWSGLUE_LIBS_SSO_BRANCH} ${AWSGLUE_LIBS_SSO_REPO} ${AWSGLUE_LIBS_SSO_PATH}
RUN cp -r ${AWSGLUE_LIBS_SSO_PATH}/sso-support/* /project/
RUN mvn package

##############################
#### STAGE: awsglue source ###
##############################

# Source Image
FROM ${AWSGLUE_DOCKER_IMAGE} AS awsglue-source

##############################
#### STAGE: awsglue image ####
##############################

# Final Image
FROM ${AMAZONLINUX_DOCKER_IMAGE} as awsglue

# Consume build arguments in this build stage
# (global scope build arguments are not automatically inherited into the build stages)
ARG GLUE_USER
ARG GLUE_LIBS_DIR
ARG GLUE_HOME
ARG GLUE_AWS
ARG GLUE_CHOWN

ARG TARGETARCH=amd64
ARG BUILD_VER=glue-v4-container-amazonlinux-2023
ENV LANG=en_US.UTF-8

RUN dnf update -y && dnf install -y zip krb5-devel shadow-utils lzo wget bind-utils tar vim gcc hostname \
    openssl openssl-devel awscli java-1.8.0-amazon-corretto libjpeg-turbo-devel zlib-devel zlib-static \
    bzip2-devel make libffi-devel sqlite-devel xz-devel python3-devel \
    readline-devel ncurses-devel libuuid-devel gdbm-devel automake autoconf lapack-devel \
    blas-devel cmake git &&\
    dnf groupinstall -y "Development Tools" &&\
    dnf clean all &&\
    rm -rf /var/cache/dnf &&\
    useradd -r -u 10000 -g root glue_user --create-home

USER glue_user

ENV PYSPARK_PYTHON=python3
ENV SPARK_HOME=${GLUE_HOME}/spark
ENV SPARK_CONF_DIR=${GLUE_HOME}/spark/conf
ENV PYTHONPATH=${GLUE_HOME}/aws-glue-libs/PyGlue.zip:${GLUE_HOME}/spark/python/lib/py4j-0.10.9.5-src.zip:${GLUE_HOME}/spark/python/
ENV PYSPARK_PYTHON_DRIVER=python3
ENV HADOOP_CONF_DIR=${GLUE_HOME}/spark/conf
ENV LIVY_INTEGRATION_TEST=true

RUN mkdir -p ${GLUE_HOME}/aws-glue-libs && chown ${GLUE_CHOWN} ${GLUE_HOME}/aws-glue-libs

COPY --from=awsglue-source /usr/share/log4j-cve-2021-44228-hotpatch/jdk17/Log4jHotPatchFat.jar /usr/share/log4j-cve-2021-44228-hotpatch/jdk17/Log4jHotPatchFat.jar
COPY --from=awsglue-source ${GLUE_HOME}/aws-glue-libs/PyGlue.zip ${GLUE_HOME}/aws-glue-libs/PyGlue.zip
COPY --from=awsglue-source --chown=${GLUE_CHOWN} ${GLUE_LIBS_DIR}/ ${GLUE_LIBS_DIR}/
COPY --from=awsglue-source --chown=${GLUE_CHOWN} ${GLUE_HOME}/spark/ ${GLUE_HOME}/spark/
COPY --from=awsglue-source --chown=${GLUE_CHOWN} ${GLUE_HOME}/livy/ ${GLUE_HOME}/livy/
COPY --from=awsglue-source --chown=${GLUE_CHOWN} ${GLUE_HOME}/.bashrc ${GLUE_HOME}/.bashrc
COPY --from=awsglue-source --chown=${GLUE_CHOWN} ${GLUE_HOME}/.sparkmagic/config.json ${GLUE_HOME}/.sparkmagic/config.json
COPY --from=awsglue-source --chown=${GLUE_CHOWN} ${GLUE_HOME}/.jupyter/lab/user-settings ${GLUE_HOME}/.jupyter/lab/user-settings
COPY --from=awsglue-source --chown=${GLUE_CHOWN} ${GLUE_HOME}/jupyter/jupyter_start.sh ${GLUE_HOME}/jupyter/jupyter_start.sh
COPY --from=awsglue-source --chown=${GLUE_CHOWN} ${GLUE_HOME}/.certs/ssl_tls_setup.py ${GLUE_HOME}/.certs/ssl_tls_setup.py
COPY --from=awsglue-source --chown=${GLUE_CHOWN} ${GLUE_HOME}/.certs/aws_tls_certs/InternalAndExternalAndAWSTrustStore.jks ${GLUE_HOME}/.certs/aws_tls_certs/InternalAndExternalAndAWSTrustStore.jks
COPY --from=awsglue-source --chown=${GLUE_CHOWN} ${GLUE_HOME}/aws-glue-libs/datalake-connectors ${GLUE_HOME}/aws-glue-libs/datalake-connectors

COPY --from=build-jar-sso --chown=${GLUE_CHOWN} "/project/target/*.jar" "${GLUE_LIBS_DIR}/"

RUN echo "BUILD_VER: ${BUILD_VER}" > $HOME/image_build_ver.txt && printf "numpy<2" > /tmp/constraint.txt &&\
     export PATH=$HOME/.local/bin:$PATH &&\
     python3 -m ensurepip --upgrade &&\
     python3 -m pip install --upgrade pip wheel &&\
     rm -r ~/.cache/ &&\
     pip3 install --constraint /tmp/constraint.txt --user sparkmagic==0.21.0 jupyterlab==4.2.5 ipykernel==6.29.5 ipywidgets==8.1.5 jupyterlab_widgets==3.0.13 pytest boto==2.49.0 &&\
     jupyter-kernelspec install --user $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/sparkkernel &&\
     jupyter-kernelspec install --user $(pip show sparkmagic | grep Location | cut -d" " -f2)/sparkmagic/kernels/pysparkkernel &&\
     jupyter server extension enable --user --py sparkmagic &&\
     mkdir -p ${GLUE_HOME}/workspace/ ${GLUE_HOME}/.jupyter/lab/user-settings/ /tmp/spark-events &&\
     chmod a+x ${GLUE_HOME}/jupyter/jupyter_start.sh &&\
     chown -R ${GLUE_CHOWN} /tmp/spark-events &&\
     chown -R ${GLUE_CHOWN} ${GLUE_HOME}/ &&\
     ln -s $(which openssl) $HOME/.local/bin/openssl && git clone https://github.com/awslabs/git-secrets.git /tmp/git-secrets &&\
     pushd /tmp/git-secrets &&\
     PREFIX=$HOME/.local/ make install &&\
     popd &&\
     rm -rf /tmp/git-secrets

COPY --from=awsglue-source /usr/local/share/jupyter/kernels/pysparkkernel/kernel.json /usr/local/share/jupyter/kernels/pysparkkernel/kernel.json
COPY --from=awsglue-source /usr/local/share/jupyter/kernels/sparkkernel/kernel.json /usr/local/share/jupyter/kernels/sparkkernel/kernel.json
COPY --from=awsglue-source --chown=${GLUE_CHOWN} ${GLUE_HOME}/livy/conf ${GLUE_HOME}/livy/conf
COPY --from=awsglue-source --chown=${GLUE_CHOWN} ${GLUE_HOME}/.jupyter/lab/user-settings ${GLUE_HOME}/.jupyter/lab/user-settings
COPY --from=awsglue-source --chown=${GLUE_CHOWN} ${GLUE_HOME}/native_libs/amd64 ${GLUE_HOME}/native_libs/amd64

ENV PATH="${GLUE_HOME}/.local/bin:$PATH"

RUN pip3 install --user Cython==0.29.32 &&\
     pip3 install --user pmdarima==2.0.1 &&\
     pip3 install --user statsmodels==0.13.5 &&\
     pip3 install --user s3fs==2022.11.0 &&\
     pip3 install --user tbats==1.1.0 &&\
     pip3 install --user --upgrade setuptools==49.1.3 &&\
     pip3 install --user wheel==0.37.0 &&\
     pip3 install --user matplotlib==3.4.3 &&\
     pip3 install --user subprocess32==3.5.4 &&\
     pip3 install --user ptvsd==4.3.2 &&\
     pip3 install --user pydevd==2.5.0 &&\
     pip3 install --user PyMySQL==1.0.2 &&\
     pip3 install --user docutils==0.17.1 &&\
     pip3 install --user jmespath==0.10.0 &&\
     pip3 install --user six==1.16.0 &&\
     pip3 install --user python_dateutil==2.8.2 &&\
     pip3 install --user urllib3==1.26.6 &&\
     pip3 install --user botocore==1.27.96 &&\
     pip3 install --user s3transfer==0.6.0 &&\
     pip3 install --user boto3==1.24.70 &&\
     pip3 install --user aiobotocore==2.4.1 &&\
     pip3 install --user certifi==2021.5.30 &&\
     pip3 install --user chardet==4.0.0 &&\
     pip3 install --user idna==3.2 &&\
     pip3 install --user requests==2.23.0 &&\
     pip3 install --user pyparsing==2.4.7 &&\
     pip3 install --user enum34==1.1.10 &&\
     pip3 install --user pytz==2021.1 &&\
     pip3 install --user cycler==0.10.0 &&\
     pip3 install --user kiwisolver==1.4.4 &&\
     pip3 install --user scipy==1.9.3 &&\
     pip3 install --user pandas==1.5.1 &&\
     pip3 install --user pyarrow==10.0.0 &&\
     pip3 install --user pyhocon==0.3.58 &&\
     pip3 install --user mpmath==1.2.1 &&\
     pip3 install --user sympy==1.8 &&\
     pip3 install --user patsy==0.5.3 &&\
     pip3 install --user fsspec==2021.8.1 &&\
     pip3 install --user joblib==1.0.1 &&\
     pip3 install --user scikit-learn==1.1.3 &&\
     pip3 install --user PyYaml==6.0.1 &&\
     pip3 install --user nltk==3.7 &&\
     pip3 install --user avro-python3==1.10.2 &&\
     pip3 install --user numpy==1.23.5 &&\
     pip3 install --user aiohttp==3.8.3 &&\
     pip3 install --user aioitertools==0.11.0 &&\
     pip3 install --user aiosignal==1.3.1 &&\
     pip3 install --user async-timeout==4.0.2 &&\
     pip3 install --user asynctest==0.13.0 &&\
     pip3 install --user attrs==22.2.0 &&\
     pip3 install --user charset-normalizer==2.1.1 &&\
     pip3 install --user click==8.1.3 &&\
     pip3 install --user frozenlist==1.3.3 &&\
     pip3 install --user importlib-metadata==5.0.0 &&\
     pip3 install --user multidict==6.0.4 &&\
     pip3 install --user packaging==23.0 &&\
     pip3 install --user patsy==0.5.1 &&\
     pip3 install --user Pillow==9.4.0 &&\
     pip3 install --user python-dateutil==2.8.2 &&\
     pip3 install --user regex==2022.10.31 &&\
     pip3 install --user threadpoolctl==3.1.0 &&\
     pip3 install --user tqdm==4.64.1 &&\
     pip3 install --user typing_extensions==4.4.0 &&\
     pip3 install --user wrapt==1.14.1 &&\
     pip3 install --user yarl==1.8.1 &&\
     pip3 install --user zipp==3.10.0 &&\
     pip3 install --user importlib-metadata==5.0.0 &&\
     pip3 install --user wrapt==1.14.1 &&\
     pip3 install --user yarl==1.8.2 &&\
     pip3 install --user seaborn==0.12.2 &&\
     pip3 install --user plotly==5.16.0 &&\
     pip3 install --user kaleido==0.2.1 &&\
     pip3 install --user typing-extensions==4.12.2 &&\
     rm -r ~/.cache/pip/selfcheck/

ADD --chown=${GLUE_CHOWN} jupyter.sh ${GLUE_HOME}/jupyter/jupyter.sh
RUN mkdir ${GLUE_HOME}/jupyter/logs

# Fix SLF4J: Class path contains multiple SLF4J bindings.
RUN rm ${GLUE_HOME}/spark/jars/slf4j-reload4j-1.7.36.jar ${GLUE_LIBS_DIR}/slf4j-reload4j-1.7.36.jar ${GLUE_LIBS_DIR}/log4j-slf4j-impl-2.17.2.jar

# Fix log4j:WARN No appenders could be found for logger (org.apache.hadoop.metrics2.lib.MutableMetricsFactory).
ADD --chown=${GLUE_CHOWN} log4j.properties ${GLUE_HOME}/spark/conf/log4j.properties
RUN echo "spark.driver.extraJavaOptions=-Dlog4j.configurationFile=${GLUE_HOME}/spark/conf/log4j.properties" >> ${GLUE_HOME}/spark/conf/spark-defaults.conf && \
    echo "spark.executor.extraJavaOptions=-Dlog4j.configurationFile=${GLUE_HOME}/spark/conf/log4j.properties" >> ${GLUE_HOME}/spark/conf/spark-defaults.conf

# Change spark configuration
RUN sed -i 's|com.amazonaws.auth.DefaultAWSCredentialsProviderChain|com.medianovens.aws.sdkv1.auth.sso.DefaultAWSCredentialsProviderChainWithSSO|g' ${GLUE_HOME}/spark/conf/core-site.xml && \
    sed -i 's|com.amazonaws.glue.catalog.metastore.DefaultAWSCredentialsProviderFactory|com.medianovens.aws.sdkv1.auth.sso.DefaultAWSCredentialsProviderFactoryWithSSO|g' ${GLUE_HOME}/spark/conf/core-site.xml &&\
    sed -i 's|com.amazonaws.auth.DefaultAWSCredentialsProviderChain|com.medianovens.aws.sdkv1.auth.sso.DefaultAWSCredentialsProviderChainWithSSO|g' ${GLUE_HOME}/spark/conf/spark-defaults.conf

ENV SPARK_SUBMIT_OPTS="-Dlog4j.configuration=file:${GLUE_HOME}/spark/conf/log4j2.properties"
ENV LD_LIBRARY_PATH=${GLUE_HOME}/native_libs/amd64/hadoop-lzo-native:${GLUE_HOME}/native_libs/amd64/hadoop-native/
ENV DEVCONTAINER=true

WORKDIR /workspace/project/

EXPOSE 18080/tcp 4040/tcp 8889/tcp 8998/tcp

CMD ["/bin/bash"]