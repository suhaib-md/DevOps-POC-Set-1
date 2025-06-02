import org.sonatype.nexus.repository.Repository
import org.sonatype.nexus.repository.manager.RepositoryManager
import org.sonatype.nexus.repository.maven.LayoutPolicy
import org.sonatype.nexus.repository.maven.VersionPolicy
import org.sonatype.nexus.repository.config.Configuration
import org.sonatype.nexus.repository.storage.WritePolicy

// Get repository manager
repositoryManager = container.lookup(RepositoryManager.class.getName())

// Create Maven repositories
def createMavenProxy(String name, String remoteUrl) {
    def existingRepo = repositoryManager.get(name)
    if (existingRepo == null) {
        log.info("Creating Maven proxy repository: " + name)
        
        Configuration config = new Configuration(
            repositoryName: name,
            recipeName: 'maven2-proxy',
            online: true,
            attributes: [
                maven: [
                    versionPolicy: VersionPolicy.MIXED,
                    layoutPolicy: LayoutPolicy.STRICT
                ],
                proxy: [
                    remoteUrl: remoteUrl,
                    contentMaxAge: 1440,
                    metadataMaxAge: 1440
                ],
                httpclient: [
                    blocked: false,
                    autoBlock: true
                ],
                storage: [
                    blobStoreName: 'default',
                    strictContentTypeValidation: true
                ]
            ]
        )
        
        repositoryManager.create(config)
        log.info("Created Maven proxy repository: " + name)
    } else {
        log.info("Maven proxy repository already exists: " + name)
    }
}

def createMavenHosted(String name) {
    def existingRepo = repositoryManager.get(name)
    if (existingRepo == null) {
        log.info("Creating Maven hosted repository: " + name)
        
        Configuration config = new Configuration(
            repositoryName: name,
            recipeName: 'maven2-hosted',
            online: true,
            attributes: [
                maven: [
                    versionPolicy: VersionPolicy.MIXED,
                    layoutPolicy: LayoutPolicy.STRICT
                ],
                storage: [
                    blobStoreName: 'default',
                    strictContentTypeValidation: true,
                    writePolicy: WritePolicy.ALLOW_ONCE
                ]
            ]
        )
        
        repositoryManager.create(config)
        log.info("Created Maven hosted repository: " + name)
    } else {
        log.info("Maven hosted repository already exists: " + name)
    }
}

def createMavenGroup(String name, List<String> memberNames) {
    def existingRepo = repositoryManager.get(name)
    if (existingRepo == null) {
        log.info("Creating Maven group repository: " + name)
        
        Configuration config = new Configuration(
            repositoryName: name,
            recipeName: 'maven2-group',
            online: true,
            attributes: [
                maven: [
                    versionPolicy: VersionPolicy.MIXED,
                    layoutPolicy: LayoutPolicy.STRICT
                ],
                group: [
                    memberNames: memberNames
                ],
                storage: [
                    blobStoreName: 'default',
                    strictContentTypeValidation: true
                ]
            ]
        )
        
        repositoryManager.create(config)
        log.info("Created Maven group repository: " + name)
    } else {
        log.info("Maven group repository already exists: " + name)
    }
}

// Create Docker repositories
def createDockerHosted(String name, int httpPort) {
    def existingRepo = repositoryManager.get(name)
    if (existingRepo == null) {
        log.info("Creating Docker hosted repository: " + name)
        
        Configuration config = new Configuration(
            repositoryName: name,
            recipeName: 'docker-hosted',
            online: true,
            attributes: [
                docker: [
                    httpPort: httpPort,
                    httpsPort: null,
                    forceBasicAuth: true,
                    v1Enabled: false
                ],
                storage: [
                    blobStoreName: 'default',
                    strictContentTypeValidation: true,
                    writePolicy: WritePolicy.ALLOW
                ]
            ]
        )
        
        repositoryManager.create(config)
        log.info("Created Docker hosted repository: " + name)
    } else {
        log.info("Docker hosted repository already exists: " + name)
    }
}

// Create repositories
try {
    // Maven repositories
    createMavenProxy('maven-central', 'https://repo1.maven.org/maven2/')
    createMavenProxy('maven-google', 'https://maven.google.com/')
    createMavenProxy('gradle-plugins', 'https://plugins.gradle.org/m2/')
    
    createMavenHosted('maven-releases')
    createMavenHosted('maven-snapshots')
    
    createMavenGroup('maven-public', ['maven-releases', 'maven-snapshots', 'maven-central', 'maven-google'])
    
    // Docker repositories
    createDockerHosted('docker-hosted', 8082)
    
    log.info("Repository initialization completed successfully")
    
} catch (Exception e) {
    log.error("Error during repository initialization: " + e.getMessage(), e)
}
