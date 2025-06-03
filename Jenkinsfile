pipeline {
  agent any

  environment {
    IMAGE = "eve56/demo-app"
    TAG = "latest"
    DOCKER_CRED = "docker-hub"
    KUBECONFIG_CRED = "kubeconfig-dev"
    NAMESPACE = "default"
    HELM_RELEASE = "casestudy-jenkins1"
  }

  stages {
    stage('Checkout Source Code') {
      steps {
        git url: 'https://github.com/Rintan28/casestudy-jenkins.git', branch: 'main'
      }
    }

    stage('Build Docker Image') {
      steps {
        script {
          echo "🛠️ Building image ${IMAGE}:${TAG}..."
          // Cek isi workspace
          sh 'pwd'
          sh 'ls -la'

          // Pastikan kita di direktori yang punya Dockerfile & .dockerignore
          dir('.') {
            def builtImage = docker.build("${IMAGE}:${TAG}", '.')
          }
        }
      }
    }

    stage('Push Docker Image') {
      steps {
        withCredentials([usernamePassword(
          credentialsId: "docker-hub",
          usernameVariable: 'USER',
          passwordVariable: 'PASS'
        )]) {
          script {
            echo "📦 Pushing image to DockerHub..."
            sh """
              echo "$PASS" | docker login -u "$USER" --password-stdin
              docker push ${IMAGE}:${TAG}
            """
          }
        }
      }
    }

    stage('Deploy to Kubernetes (Helm)') {
      agent {
        docker {
            image 'eve56/demo-app' // <-- pakai image buatan kamu yang sudah ada helm-nya
        }
      }
      
      steps {
        withCredentials([file(credentialsId: "${KUBECONFIG_CRED}")]) {
          script {
            echo "🚀 Deploying to Kubernetes via Helm..."
            sh '''
              export KUBECONFIG=~/.kube/config
              helm upgrade --install $HELM_RELEASE ./helm \
                --set image.repository=$IMAGE \
                --set image.tag=$TAG \
                --namespace $NAMESPACE --create-namespace
            '''
          }
        }
      }
    }
  }

  post {
    success {
      echo "✅ Pipeline Sukses: Aplikasi berhasil dideploy ke Kubernetes"
    }
    failure {
      echo "❌ Pipeline Gagal: Cek log untuk mengetahui error"
    }
  }
}
