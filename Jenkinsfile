pipeline {
    agent any

    environment {
        DOCKER_HUB_REPO = 'villers118/techsolutions-app'
        KUBECONFIG = '/home/cr/.kube/config'
        NAMESPACE = 'default'
        APP_NAME = 'techsolutions'
    }

    stages {
        stage('Checkout') {
            steps {
                echo 'Checking out sourcecode'
                git branch: 'feature/my-new-feature',
                    url: 'https://github.com/villeog/microservices-ingress-kastro.git'
            }
        }

        stage('Build Docker Image') {
            steps {
                echo 'Building Docker image...'
                script {
                    def buildNumber = env.BUILD_NUMBER
                    def imageTag = "${DOCKER_HUB_REPO}:${buildNumber}"
                    def latestTag = "${DOCKER_HUB_REPO}:latest"

                    sh "docker build -t ${imageTag} ."
                    sh "docker tag ${imageTag} ${latestTag}"

                    env.IMAGE_TAG = buildNumber
                }
            }
        }

        stage('Push to DockerHub') {
            steps {
                echo 'Pushing Docker image to DockerHub...'
                script {
                    withCredentials([usernamePassword(credentialsId: 'dockerhub-creds', passwordVariable: 'DOCKER_PASSWORD', usernameVariable: 'DOCKER_USERNAME')]) {
                        sh "echo \${DOCKER_PASSWORD} | docker login -u \${DOCKER_USERNAME} --password-stdin"
                        sh "docker push ${DOCKER_HUB_REPO}:${env.IMAGE_TAG}"
                        sh "docker push ${DOCKER_HUB_REPO}:latest"
                    }
                }
            }
        }

        stage('🔧 Configure Local Kubectl') {
            steps {
                echo '🔍 Verifying local Kubernetes context...'
                withEnv(["KUBECONFIG=$KUBECONFIG"]) {
                    sh '''
                    kubectl config current-context
                    kubectl get nodes -o wide
                    '''
                }
            }
        }

        stage('📤 Deploy to Local Kubernetes') {
            steps {
                echo '📤 Deploying application to local Kubernetes cluster...'
                withEnv(["KUBECONFIG=$KUBECONFIG"]) {
                    sh '''
                    echo "🧪 Replacing image tag in deployment..."
                    sed -i "s|kastrov/techsolutions-app:latest|kastrov/techsolutions-app:${IMAGE_TAG}|g" k8s/deployment.yaml

                    echo "🚀 Applying deployment..."
                    kubectl apply -f k8s/deployment.yaml

                    echo "⏳ Waiting for rollout..."
                    kubectl rollout status deployment/${DEPLOYMENT_NAME} --timeout=300s

                    echo "🔍 Verifying pods and service..."
                    kubectl get pods -l app=${APP_NAME}
                    kubectl get svc ${SERVICE_NAME}
                    '''
                }
            }
        }

        stage('🌐 Deploy Ingress') {
            steps {
                echo '🌐 Deploying Ingress resource...'
                withEnv(["KUBECONFIG=$KUBECONFIG"]) {
                    sh '''
                    echo "🌐 Applying ingress resource..."
                    kubectl apply -f k8s/ingress.yaml

                    echo "⏳ Waiting for ingress to stabilize..."
                    sleep 10

                    echo "🔍 Inspecting ingress status..."
                    kubectl get ingress ${APP_NAME}-ingress
                    kubectl describe ingress ${APP_NAME}-ingress

                    echo "📡 Verifying ingress controller..."
                    kubectl get svc ingress-nginx-controller -n ingress-nginx
                    '''
                }
            }
        }

        stage('🌐 Get Ingress URL') {
            steps {
                echo '🌐 Getting Ingress URL...'
                withEnv(["KUBECONFIG=$KUBECONFIG"]) {
                    script {
                        def ingress_ip = sh(
                            script: "kubectl get svc ingress-nginx-controller -n ingress-nginx -o jsonpath='{.spec.clusterIP}'",
                            returnStdout: true
                        ).trim()

                        if (!ingress_ip) {
                            error "❌ Ingress controller IP not found."
                        }

                        env.INGRESS_URL = "http://${ingress_ip}"
                        echo "✅ Ingress URL: ${env.INGRESS_URL}"

                        echo "========================================="
                        echo "DEPLOYMENT SUCCESSFUL!"
                        echo "========================================="
                        echo "Application URL: ${env.INGRESS_URL}"
                        echo ""
                        echo "Available Paths:"
                        echo "- Home Page: ${env.INGRESS_URL}/"
                        echo "- About Page: ${env.INGRESS_URL}/about"
                        echo "- Services Page: ${env.INGRESS_URL}/services"
                        echo "- Contact Page: ${env.INGRESS_URL}/contact"
                        echo "========================================="

                        sh "curl -I ${env.INGRESS_URL}/ || echo 'Home page check failed'"
                        sh "curl -I ${env.INGRESS_URL}/about || echo 'About page check failed'"
                        sh "curl -I ${env.INGRESS_URL}/services || echo 'Services page check failed'"
                        sh "curl -I ${env.INGRESS_URL}/contact || echo 'Contact page check failed'"
                    }
                }
            }
        }


        

       

        post {
            always {
                echo 'Cleaning up Docker images...'
                sh "docker rmi ${DOCKER_HUB_REPO}:${env.IMAGE_TAG} || true"
                sh "docker rmi ${DOCKER_HUB_REPO}:latest || true"
            }

            success {
                echo 'Pipeline completed successfully!'
                echo "Access your application at: ${env.INGRESS_URL}"
            }

            failure {
                echo 'Pipeline failed! Please check the logs.'
            }
        }
    }


}
