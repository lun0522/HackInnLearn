package com.example.missa.mitext;

import android.os.AsyncTask;
import android.os.Handler;
import android.support.v7.app.AppCompatActivity;
import android.os.Bundle;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.Button;
import android.widget.EditText;
import android.widget.ListView;

import java.io.BufferedReader;
import java.io.IOException;
import java.io.InputStreamReader;
import java.net.InetAddress;
import java.net.Socket;
import java.util.ArrayList;

public class MainActivity extends AppCompatActivity {

    Handler UIHandler;

    Thread Thread1 = null;

    //For displaying Text Messages
    //ArrayList<String> messagesList = new ArrayList<>();
    ListView messages;
    //ArrayAdapter arrayAdapter;

    private EditText EDITTEXT;

    public static final int SERVERPORT = 8100;
    public static final String SERVERIP = "10.200.0.123";

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);

        setContentView(R.layout.activity_main);

        // Set up display of messages
        messages = (ListView) findViewById(R.id.messages);
//        input = (EditText) findViewById(R.id.input);
//        arrayAdapter = new ArrayAdapter<>(this, android.R.layout.simple_list_items_1, messagesList);
//        messages.setAdapter(arrayAdapter);

        EDITTEXT = (EditText) findViewById(R.id.edit_text);

        UIHandler = new Handler();

        this.Thread1 = new Thread(new Thread1());
        this.Thread1.start();

    }

    class Thread1 implements Runnable {

        public void run() {
            Socket socket = null;

            try {

                InetAddress serverAddress = InetAddress.getByName(SERVERIP);
                socket = new Socket(serverAddress, SERVERPORT);

                Thread2 communicationThread = new Thread2(socket);
                new Thread(communicationThread).start();
                return;
            } catch (IOException e) {
                e.printStackTrace();
            }
        }
    }

    class Thread2 implements Runnable {
        private Socket clientSocket;

        private BufferedReader input;

        public Thread2(Socket clientSocket) {
            this.clientSocket = clientSocket;

            try {
                this.input = new BufferedReader(new InputStreamReader(this.clientSocket.getInputStream()));
            } catch (IOException e) {
                e.printStackTrace();
            }
        }

        public void run() {

            while (!Thread.currentThread().isInterrupted()) {
                try {
                    String read = input.readLine();
                    if(read != null) {
                        UIHandler.post(new updateUIThread(read));
                    } else {
                        Thread1 = new Thread(new Thread1());
                        Thread1.start();
                        return;
                    }
                } catch (IOException e) {
                    e.printStackTrace();
                }
            }
        }
    }

    class updateUIThread implements Runnable {
        private String msg;

        public updateUIThread(String str) {
            this.msg =str;
        }

        @Override
        public void run() {
            EDITTEXT.setText(EDITTEXT.getText().toString() + msg + "\n");
        }
    }


    public void sendMessage(View view) {
        //TODO: send/display text to other user
    }


}
