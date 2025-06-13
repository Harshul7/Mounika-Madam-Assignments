#include <stdio.h> //for printf,perror,snprintf 
#include <stdlib.h>// for exit,EXIT_FAILURE
#include <sys/stat.h>//for mkdir and file permissions
#include <fcntl.h>//for open flags
#include <unistd.h>//for read,write,lseek,close
#include <string.h>//for string functions(strchr)
#include <errno.h>//for errno(to handle errors)

#define CHUNK_SIZE 8192  // 8KB chunks for processing
//when reading large files instead of reading whole file into memeory at once,we read it in small parts or chunks to save memory and improve I/O performance

int main(int argc, char *argv[]) {
    /* program starts from main
    argc-argument count- the no of arguments that are passed
    argv-argument vector- an array of strings (as char *) is given where each element is an argument 
    argv[0]
    argv[1]...
    
    line no:21 checks for argc=2 if not then it print message and exit the program 
    */
    if (argc != 2) {
        fprintf(stderr, "Wrong command: %s <Input_file_path>\n", argv[0]);
        exit(EXIT_FAILURE);
    }
    //ex: argv[1] is the input file and dir_name is the directory of the output

    const char *input_file_path = argv[1];
    const char *dir_name = "Assignment";

    /*Get the input file name from the path
    strchr searches backwards in the input file for the last occurance of the character '/' 
    if it is found then it returns a pointer to this character,
    otherwise it returns NULL
    ex:"folder1/folder2/file1.txt" strchr points to /file1.txt---->we are incrementing to skip / and to extract filename(file1.txt)
    if no '/' is found then the file name is the whole path
    */
    const char *input_file_name = strrchr(input_file_path, '/');
    if (input_file_name)
        input_file_name++; // Skip the '/'
    else
        input_file_name = input_file_path;

    /*
    mkdir(dir_name,0700) creates the directory
    0700-permissions to read write execute,no access to groups and others(4-read,2-write,1-execute)
    if mkdir fails in creating directory then it returns -1
    errno is a global variable set by the system calls when an error occurs
    if errno == EEXIST that means directory already exists and we ignore this error
    if errno  is not EEXIST ,it means that something went wrong like permission denied, no disk space etc.
    then perror prints the error message along with mkdir and EXIT_FAILURE exits the program with failure status    */
    if (mkdir(dir_name, 0700) == -1) {
        if (errno != EEXIST) {
            perror("mkdir failed");
            exit(EXIT_FAILURE);
        }
    }

    /*
    syntax:
    sprintf(char *str,const char *format,....);
    str: it is the destination buffer 
    size: the maximum number of bytes to write including null terminator(\0)
    format: a format string similiar to printf 
    ..... : the values to format
    */
    char output_file_path[1024];
    sprintf(output_file_path, "%s/1_%s", dir_name, input_file_name);

    /* opens the input file for reading
    open is a system call that opens the file 
    input_file_path is the path to the file that we want to open
    O_RDONLY- read only mode
    open returns the file descriptor if successful if it fails it returns -1
    */
    int input_fd = open(input_file_path, O_RDONLY);
    if (input_fd == -1) {
        perror("open input");
        exit(EXIT_FAILURE);
    }
    /*
    This line opens (or creates) a file for writing and returns a file descriptor.
    open() is a system call used to open files.
    output_file_path is a string containing the path to the output file (ex: "Assignment/1_input.txt").
    O_WRONLY: open for write-only
    O_CREAT: create the file if it doesn’t exist
    O_TRUNC: truncate the file to zero length if it already exists.
    0600: sets file permissions to read and write for the user only (rw-------)
    if output_fd returns -1 then the error message for open failure is displayed along with the open output
    ex:open output:No such file or directory -> if file cannot be opened 
    before exiting we will close the input file assuming it is opened earlier
    */

    int output_fd = open(output_file_path, O_WRONLY | O_TRUNC | O_CREAT, 0600);
    if (output_fd == -1) {
        perror("open output");
        close(input_fd);
        exit(EXIT_FAILURE);
    }

    /*
    lseek is a system call used to move the file pointer to a specified location
    input_fd is the file descriptor of the opened input file
    0 is the offset
    SEEK_END moves the file pointer to the end of the file
    The return value is the resulting offset(refers to postion in file) — which, in this case, is the size of the file in bytes
    off_t is the data type used for file sizes and offsets (typically a 64-bit signed integer).
    Assume a file has 100 bytes.

    lseek(fd, 0, SEEK_END);
    This moves the file pointer to the end of the file. The returned offset will be 100, meaning the file is 100 bytes long.
    
    lseek(fd, -10, SEEK_END);
    This moves the pointer to 10 bytes before the end — at byte position 90
    to move with the file pointer we use offset with lseek
    if lseek failed it returns -1 and print error message and close input and output files  to prevent resource leak
    Example: lseek: Bad file descriptor
    */
    off_t file_size = lseek(input_fd, 0, SEEK_END);
    if (file_size == -1) {
        perror("lseek");
        close(input_fd);
        close(output_fd);
        exit(EXIT_FAILURE);
    }

    
    //It starts as the full file size and track how many bytes of the file is left to process 
    off_t remaining = file_size;
    //It creates temporary storage to hold part of file/chunk
    char buffer[CHUNK_SIZE];
    // It tracks like how many bytes are  written to the output file
    off_t total_written = 0;
    //we will run this loop until entire file is processed
    while (remaining > 0) {
        //read full chunk if there is more number of bytes than chunk size otherwise read remaining bytes
        size_t to_read = remaining >= CHUNK_SIZE ? CHUNK_SIZE : remaining;
        /*calculate position from where to read
        If remaining = 10000 and to_read = 8192 → offset = 10000 - 8192 = 1808
        so,read 8192 bytes starting at byte 1808
        */
        off_t offset = remaining - to_read;

        /*
        lseek() moves the file pointer to offset bytes from the start of the file
        SEEK_SET tells it to count from the beginning
        If lseek fails (returns -1), print an error and stop
        */
        if (lseek(input_fd, offset, SEEK_SET) == -1) {
            perror("lseek chunk");
            break;
        }

        /*
        read() is a system call that reads data from a file
        input_fd is the file input file
        buffer is an array where the read data will be stored
        to_read is the number of bytes we want to read
        bytes_read - number of bytes that were successfully read
        if bytes_read ==0 (end of file)or -1(error) then print error message and exit the loop 
        ex:read: Input/output error
        */
        ssize_t bytes_read = read(input_fd, buffer, to_read);
        if (bytes_read <= 0) {
            perror("read");
            break;
        }

        /*
        ex if file contains: 'A' 'B' 'C' 'D' 'E'

        buffer[0] = 'A'
        
        buffer[1] = 'B'
        
        buffer[2] = 'C'
        
        buffer[3] = 'D'
        
        buffer[4] = 'E'
        
        then bytes_read = 5
        
        Loop starts from i = 0 to 1 (because 5 / 2 = 2)
        
        i=0:
        tmp = buffer[0] → 'A'
        buffer[0] = buffer[4] → 'E'
        buffer[4] = tmp → 'A'
        
        Result:
        'E' 'B' 'C' 'D' 'A'
        
        i = 1:
        tmp = buffer[1] → 'B'
        buffer[1] = buffer[3] → 'D'
        buffer[3] = tmp → 'B'
        
        Result:
        'E' 'D' 'C' 'B' 'A'
        */
        for (ssize_t i = 0; i < bytes_read / 2; i++) {
            char temp = buffer[i];
            buffer[i] = buffer[bytes_read - i - 1];
            buffer[bytes_read - i - 1] = temp;
        }

        /*
        write() is a system call that writes data to a file
        output_fd is output file
        buffer is contains the reversed data
        bytes_read is the number of bytes that was read and reversed
        bytes_written is the number of bytes actually written
        If the no of bytes read is not equal to bytes written there is some error occured 
        maybe a disk error, permission issue, or disk is full then it prints an error message and exits the Loop
        ex:write: No space left on device
        */
        ssize_t bytes_written = write(output_fd, buffer, bytes_read);
        if (bytes_written != bytes_read) {
            perror("write");
            break;
        }
        /*
        total_written keeps track of total no of bytes that are written
        */
        total_written += bytes_written;

        // Calculate percentage written
        char percentBuffer[100];
        double percent = (total_written *100.0) / file_size;
        sprintf(percentBuffer,"\rProgress: %.2f%%", percent);
        write(1,percentBuffer,strlen(percentBuffer));//write the percentBuffer to stdout
        //to immediately force the output to terminal we use fflush otherwise output might be delayed
        fflush(stdout);
        //Subtract the number of bytes that is read from the remaining file content. When remaining = 0 → all chunks have been processed.
        remaining -= to_read;
    }

    close(input_fd);
    close(output_fd);
    return 0;
}