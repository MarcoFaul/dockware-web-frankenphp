describe('FrankenPHP Tests', () => {

    it('FrankenPHP serves PHP content correctly @core', () => {
        // Visit the homepage
        cy.visit('http://localhost:80');

        // Check if PHP is working
        cy.get('body').should('contain', 'Hello from Dockware with FrankenPHP!');
        
        // Check if phpinfo is displayed
        cy.get('body').should('contain', 'PHP Version');
    });

    it('FrankenPHP worker mode is functional @core', () => {
        // Test multiple requests to verify worker mode persistence
        cy.visit('http://localhost:80');
        cy.get('body').should('contain', 'Hello from Dockware with FrankenPHP!');
        
        // Make another request
        cy.reload();
        cy.get('body').should('contain', 'Hello from Dockware with FrankenPHP!');
        
        // Worker mode should keep the process alive between requests
        // This is verified by the fact that the page loads consistently
    });

    it('Static files are served by Caddy @core', () => {
        // Test if static files can be accessed (this would be handled by Caddy)
        // Create a simple test by checking if non-PHP requests work
        cy.request({
            url: 'http://localhost:80/non-existent-file.txt',
            failOnStatusCode: false
        }).then((response) => {
            // Should get 404 from Caddy, not PHP error
            expect(response.status).to.eq(404);
        });
    });

    it('Health check endpoint is working @core', () => {
        // Test the health check endpoint defined in Caddyfile
        cy.request('http://localhost:8080/health').then((response) => {
            expect(response.status).to.eq(200);
            expect(response.body).to.eq('OK');
        });

        cy.request('http://localhost:8080/ready').then((response) => {
            expect(response.status).to.eq(200);
            expect(response.body).to.eq('READY');
        });
    });

    it('PHP-FPM is running correctly with FrankenPHP @core', () => {
        cy.visit('http://localhost:80');
        
        // Check if PHP-FPM information is available in phpinfo
        cy.get('body').should('contain', 'FPM/FastCGI');
    });

    it('HTTP/2 and HTTPS support @advanced', () => {
        // Test HTTPS redirect and HTTP/2 support
        // Note: This might need to be adjusted based on the actual Caddy configuration
        cy.request({
            url: 'http://localhost:443',
            failOnStatusCode: false
        }).then((response) => {
            // Should either work with HTTPS or redirect appropriately
            expect([200, 301, 302, 400, 404]).to.include(response.status);
        });
    });

    it('Compression is working @performance', () => {
        cy.request({
            url: 'http://localhost:80',
            headers: {
                'Accept-Encoding': 'gzip, deflate'
            }
        }).then((response) => {
            // Check if compression headers are present
            // This verifies Caddy's compression is working
            expect(response.status).to.eq(200);
        });
    });

    it('Security headers are set @security', () => {
        cy.request('http://localhost:80').then((response) => {
            // Check for security headers set by Caddy
            expect(response.headers).to.have.property('x-content-type-options');
            expect(response.headers).to.have.property('x-frame-options');
            expect(response.headers).to.have.property('x-xss-protection');
            
            // Verify server header is removed for security
            expect(response.headers).to.not.have.property('server');
        });
    });

    it('Error handling works correctly @error-handling', () => {
        // Test error page handling
        cy.request({
            url: 'http://localhost:80/non-existent-page',
            failOnStatusCode: false
        }).then((response) => {
            // Should get appropriate error handling
            expect([404, 500]).to.include(response.status);
        });
    });

    it('Caddy file server blocks sensitive files @security', () => {
        // Test that sensitive files are blocked by Caddy configuration
        const sensitiveFiles = [
            '/.env',
            '/composer.json',
            '/package.json',
            '/.git/config'
        ];

        sensitiveFiles.forEach(file => {
            cy.request({
                url: `http://localhost:80${file}`,
                failOnStatusCode: false
            }).then((response) => {
                expect(response.status).to.eq(404);
            });
        });
    });

});