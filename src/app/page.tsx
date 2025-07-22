"use client";

import React from "react";
import { kubernetesDistributions } from "@/data/kubernetes";
import { Button } from "@/components/ui/button";
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card";
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogTrigger } from "@/components/ui/dialog";
import { Badge } from "@/components/ui/badge";
import { Separator } from "@/components/ui/separator";

export default function KubernetesHubPage() {
  const copyToClipboard = (text: string) => {
    navigator.clipboard.writeText(text);
  };

  return (
    <div className="min-h-screen bg-background">
      <div className="container mx-auto px-4 py-8">
        {/* Header */}
        <div className="text-center mb-12">
          <h1 className="text-4xl font-bold text-foreground mb-4">
            Kubernetes Hub
          </h1>
          <p className="text-lg text-muted-foreground max-w-2xl mx-auto">
            Explore various Kubernetes distributions with their installation scripts and prerequisites. 
            Perfect for development, testing, and production environments.
          </p>
        </div>

        {/* Kubernetes Distributions Grid */}
        <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-6">
          {kubernetesDistributions.map((distribution) => (
            <Card key={distribution.id} className="h-full flex flex-col hover:shadow-lg transition-shadow duration-200">
              <CardHeader className="pb-4">
                <CardTitle className="text-xl font-semibold text-foreground">
                  {distribution.name}
                </CardTitle>
              </CardHeader>
              <CardContent className="flex-1 flex flex-col">
                <p className="text-muted-foreground mb-6 flex-1 leading-relaxed">
                  {distribution.description}
                </p>
                <Dialog>
                  <DialogTrigger asChild>
                    <Button
                      className="w-full"
                      size="lg"
                    >
                      View Installation
                    </Button>
                  </DialogTrigger>
                  <DialogContent className="max-w-4xl max-h-[80vh] overflow-y-auto">
                    <DialogHeader>
                      <DialogTitle className="text-2xl font-bold">
                        {distribution.name} Installation Guide
                      </DialogTitle>
                    </DialogHeader>
                    
                    <div className="space-y-6">
                      {/* Description */}
                      <div>
                        <h3 className="text-lg font-semibold mb-2">Description</h3>
                        <p className="text-muted-foreground">{distribution.description}</p>
                      </div>

                      <Separator />

                      {/* Prerequisites */}
                      <div>
                        <h3 className="text-lg font-semibold mb-3">Prerequisites</h3>
                        <div className="grid grid-cols-1 gap-2">
                          {distribution.prerequisites.map((prerequisite, index) => (
                            <div key={index} className="flex items-center gap-2">
                              <Badge variant="outline" className="text-xs">
                                {index + 1}
                              </Badge>
                              <span className="text-sm">{prerequisite}</span>
                            </div>
                          ))}
                        </div>
                      </div>

                      <Separator />

                      {/* Installation Script */}
                      <div>
                        <div className="flex items-center justify-between mb-3">
                          <h3 className="text-lg font-semibold">Installation Script</h3>
                          <Button
                            variant="outline"
                            size="sm"
                            onClick={() => copyToClipboard(distribution.script)}
                          >
                            Copy Script
                          </Button>
                        </div>
                        <div className="bg-muted p-4 rounded-lg">
                          <code className="text-sm font-mono whitespace-pre-wrap break-all">
                            {distribution.script}
                          </code>
                        </div>
                      </div>

                      {/* Usage Instructions */}
                      <div className="bg-yellow-50 dark:bg-yellow-900/20 p-4 rounded-lg border border-yellow-200 dark:border-yellow-800">
                        <h4 className="font-semibold text-yellow-800 dark:text-yellow-200 mb-2">
                          Installation Instructions
                        </h4>
                        <ol className="text-sm text-yellow-700 dark:text-yellow-300 space-y-1">
                          <li>1. Ensure all prerequisites are met</li>
                          <li>2. Copy the installation script above</li>
                          <li>3. Open your terminal</li>
                          <li>4. Paste and execute the script</li>
                          <li>5. Follow any additional prompts</li>
                        </ol>
                      </div>
                    </div>
                  </DialogContent>
                </Dialog>
              </CardContent>
            </Card>
          ))}
        </div>

        {/* Footer */}
        <div className="mt-16 text-center">
          <p className="text-sm text-muted-foreground">
            💡 Click "View Installation" to see prerequisites and installation scripts for each Kubernetes distribution.
          </p>
        </div>
      </div>
    </div>
  );
}
