import { Request, Response } from 'express';
import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { ApiResponse } from '../../types';

interface UploadedFile {
    id: string;
    originalName: string;
    filename: string;
    path: string;
    mimetype: string;
    size: number;
    category?: string;
    uploadedAt: string;
}

class FileController {
    private files: UploadedFile[] = [];

    async uploadFile(req: Request, res: Response): Promise<void> {
        try {
            const file = req.file;
            const { category } = req.body;

            if (!file) {
                res.status(400).json({
                    success: false,
                    error: 'No file provided',
                    message: 'Please select a file to upload'
                } as ApiResponse<null>);
                return;
            }

            const uploadedFile: UploadedFile = {
                id: uuidv4(),
                originalName: file.originalname,
                filename: file.filename,
                path: file.path,
                mimetype: file.mimetype,
                size: file.size,
                category: category || 'general',
                uploadedAt: new Date().toISOString()
            };

            this.files.push(uploadedFile);

            res.status(201).json({
                success: true,
                data: {
                    id: uploadedFile.id,
                    originalName: uploadedFile.originalName,
                    size: uploadedFile.size,
                    category: uploadedFile.category,
                    uploadedAt: uploadedFile.uploadedAt
                },
                message: 'File uploaded successfully'
            } as ApiResponse<any>);
        } catch (error) {
            console.error('Upload file error:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Something went wrong during file upload'
            } as ApiResponse<null>);
        }
    }

    async downloadFile(req: Request, res: Response): Promise<void> {
        try {
            const { id } = req.params;

            const file = this.files.find(f => f.id === id);
            if (!file) {
                res.status(404).json({
                    success: false,
                    error: 'File not found',
                    message: 'The requested file was not found'
                } as ApiResponse<null>);
                return;
            }

            // Check if file exists on disk
            if (!fs.existsSync(file.path)) {
                res.status(404).json({
                    success: false,
                    error: 'File not found',
                    message: 'The file no longer exists on the server'
                } as ApiResponse<null>);
                return;
            }

            // Set headers for file download
            res.setHeader('Content-Type', file.mimetype);
            res.setHeader('Content-Disposition', `attachment; filename="${file.originalName}"`);
            res.setHeader('Content-Length', file.size.toString());

            // Stream the file
            const fileStream = fs.createReadStream(file.path);
            fileStream.pipe(res);

            fileStream.on('error', (error) => {
                console.error('File stream error:', error);
                if (!res.headersSent) {
                    res.status(500).json({
                        success: false,
                        error: 'Internal server error',
                        message: 'Error reading file'
                    } as ApiResponse<null>);
                }
            });
        } catch (error) {
            console.error('Download file error:', error);
            if (!res.headersSent) {
                res.status(500).json({
                    success: false,
                    error: 'Internal server error',
                    message: 'Something went wrong during file download'
                } as ApiResponse<null>);
            }
        }
    }

    async deleteFile(req: Request, res: Response): Promise<void> {
        try {
            const { id } = req.params;

            const fileIndex = this.files.findIndex(f => f.id === id);
            if (fileIndex === -1) {
                res.status(404).json({
                    success: false,
                    error: 'File not found',
                    message: 'The requested file was not found'
                } as ApiResponse<null>);
                return;
            }

            const file = this.files[fileIndex];

            // Delete file from disk
            if (fs.existsSync(file.path)) {
                fs.unlinkSync(file.path);
            }

            // Remove from our records
            this.files.splice(fileIndex, 1);

            res.status(200).json({
                success: true,
                data: null,
                message: 'File deleted successfully'
            } as ApiResponse<null>);
        } catch (error) {
            console.error('Delete file error:', error);
            res.status(500).json({
                success: false,
                error: 'Internal server error',
                message: 'Something went wrong during file deletion'
            } as ApiResponse<null>);
        }
    }
}

export default FileController;