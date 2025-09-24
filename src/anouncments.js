import express from 'express';
import pool from './db.js';

const router = express.Router();

router.post('/anounce',async(req,res)=>{
    const {title,content} = await req.body;
    if(!title || !content) return res.status(400).json({message:"Title and content are required."});
    try{
        pool.query('INSERT INTO anouncements (title,content) VALUES (?,?)',[title,content]);
        res.status(201).json({message:"Anouncement created successfully.",title,content});
    }catch(err){
        console.error(err);
        res.status(500).json({message:"Server error."});
    }
})