import ballerina/http;
import ballerina/jwt;

service / on new http:Listener(port) {
    resource function post login(@http:Payload record {|string username; string password;|} credentials) returns ApiResponse|http:NotFound|http:InternalServerError {
        User? authenticatedUser = ();

        foreach User user in users {
            if (user.username == credentials.username && user.password == credentials.password) {
                authenticatedUser = user;
                break;
            }
        }

        if (authenticatedUser == ()) {
            return http:NOT_FOUND;
        }

        do {
            string[] scopes = [];

            if (authenticatedUser.role == "admin") {
                scopes = SCOPE_ADMIN;
            } else {
                scopes = SCOPE_USER;
            }

            map<json> customClaims = {
                "scope": scopes.length() == 1 ? scopes[0] : scopes.toString()
            };

            jwt:IssuerConfig issuerConfig = {
                username: authenticatedUser.username,
                issuer: "wso2",
                expTime: 3600,
                customClaims: customClaims,
                signatureConfig: {
                    config: {
                        keyFile: "./resources/private.key"
                    }
                }
            };

            string jwt = check jwt:issue(issuerConfig);

            ApiResponse response = {
                success: true,
                message: "Login successful",
                payload: {
                    token: jwt
                }
            };

            return response;
        } on fail {
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    @http:ResourceConfig {
        auth: [
            {
                jwtValidatorConfig: JWT_VALIDATOR_CONFIG,
                scopes: SCOPE_ALL
            }
        ]
    }
    resource function get albums() returns ApiResponse {
        ApiResponse response = {
            success: true,
            message: "Albums retrieved successfully",
            payload: {
                data: albums.toArray()
            }
        };

        return response;
    }

    @http:ResourceConfig {
        auth: [
            {
                jwtValidatorConfig: JWT_VALIDATOR_CONFIG,
                scopes: SCOPE_ALL
            }
        ]
    }
    resource function get albums/[string id]() returns ApiResponse|http:NotFound {
        Album? album = albums[id];

        if (album is ()) {
            return http:NOT_FOUND;
        }

        ApiResponse response = {
            success: true,
            message: "Album retrieved successfully",
            payload: {
                data: album
            }
        };

        return response;
    }

    @http:ResourceConfig {
        auth: [
            {
                jwtValidatorConfig: JWT_VALIDATOR_CONFIG,
                scopes: SCOPE_ADMIN
            }
        ]
    }
    resource function post albums(@http:Payload Album newAlbum) returns ApiResponse|http:BadRequest|http:InternalServerError {
        do {
            Album? existingAlbum = albums[newAlbum.id];

            if (existingAlbum is Album) {
                return http:BAD_REQUEST;
            }

            ApiResponse response = {
                success: true,
                message: "Album added successfully",
                payload: {
                    data: newAlbum
                }
            };

            return response;
        } on fail {
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    @http:ResourceConfig {
        auth: [
            {
                jwtValidatorConfig: JWT_VALIDATOR_CONFIG,
                scopes: SCOPE_ADMIN
            }
        ]
    }
    resource function put albums/[string id](@http:Payload Album updatedAlbum) returns ApiResponse|http:NotFound|http:InternalServerError {
        do {
            Album? existingAlbum = albums[id];

            if (existingAlbum is ()) {
                return http:NOT_FOUND;
            }

            albums.put(updatedAlbum);

            ApiResponse response = {
                success: true,
                message: "Album updated successfully",
                payload: {
                    data: updatedAlbum
                }
            };

            return response;
        } on fail {
            return http:INTERNAL_SERVER_ERROR;
        }
    }

    @http:ResourceConfig {
        auth: [
            {
                jwtValidatorConfig: JWT_VALIDATOR_CONFIG,
                scopes: SCOPE_ADMIN
            }
        ]
    }
    resource function delete albums/[string id]() returns ApiResponse|http:NotFound|http:InternalServerError {
        do {
            Album? existingAlbum = albums[id];

            if (existingAlbum is ()) {
                return http:NOT_FOUND;
            }

            _ = albums.remove(id);

            ApiResponse response = {
                success: true,
                message: "Album deleted successfully",
                payload: {
                    data: existingAlbum
                }
            };

            return response;
        } on fail {
            return http:INTERNAL_SERVER_ERROR;
        }
    }
}
