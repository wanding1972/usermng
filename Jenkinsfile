pipeline {
  agent any
  stages {
    stage('staticcheck') {
      parallel {
        stage('staticcheck') {
          steps {
            echo 'print staticcheck'
            sh 'sonatype.sh'
          }
        }

        stage('staticcheck1') {
          steps {
            echo 'staticcheck1'
          }
        }

      }
    }

    stage('build') {
      parallel {
        stage('build') {
          steps {
            echo 'start build'
            sh 'mvn clean package'
          }
        }

        stage('build1') {
          steps {
            echo 'build1'
          }
        }

      }
    }

    stage('autotest') {
      steps {
        echo 'print autotest'
        sh 'mvn test'
      }
    }

    stage('lastpost') {
      steps {
        echo 'hello finished'
      }
    }

  }
  environment {
    os = 'hp'
    cust = 'liantong'
  }
}