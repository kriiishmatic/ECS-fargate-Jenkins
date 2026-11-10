
def call() {

    echo 'Starting application packaging...'

    sh """
        set -eu

        # Execute Maven package phase.
        # This also runs compile and test lifecycle phases.
        mvn -B -ntp -f "${env.POM_PATH}" package

        # Display the generated JAR files.
        echo "Generated application artifacts:"
        find target -maxdepth 1 -type f -name '*.jar' -print

        # Validate that a JAR was generated.
        JAR_FILE=\$(find target -maxdepth 1 -type f \
            -name '*.jar' \
            ! -name '*-sources.jar' \
            ! -name '*-javadoc.jar' \
            | head -n 1)

        if [ -z "\$JAR_FILE" ]; then
            echo "ERROR: Application JAR was not generated."
            exit 1
        fi

        # Capture the artifact path for subsequent pipeline stages.
        echo "Application artifact: \$JAR_FILE"
    """

    echo 'Application packaging completed successfully.'
}
