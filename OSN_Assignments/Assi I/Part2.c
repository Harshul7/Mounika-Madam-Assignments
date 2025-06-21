#include <stdio.h>      // for printf, perror, snprintf
#include <stdlib.h>     // for exit, EXIT_FAILURE
#include <sys/stat.h>   // for mkdir and permissions
#include <fcntl.h>      // for open flags(ORDONLY,O_WRONLY,etc)
#include <unistd.h>     // for read, write, lseek, close
#include <string.h>     // for string functions (strchr)
#include <errno.h>      // for errno

#define CHUNK_SIZE 8192  // 8KB chunk size

int main(int argc, char *argv[]) {
    // Check if all 3 arguments are provided: input file, number of parts, part to reverse otherwise print error 
    if (argc != 4) {
       // fprintf(stderr, "Provide correct arguments-Use:%s <Input_file_path> <No_of_parts> <Part_to_be_reversed>\n", argv[0]);
       char errBuffer[100];
       sprintf(errBuffer,"Provide correct arguments-Use:%s <Input_file_path> <No_of_parts> <Part_to_be_reversed>\n", argv[0]);
       write(2,errBuffer,strlen(errBuffer));
       exit(EXIT_FAILURE);
    }

    const char *input_file_path = argv[1];
    //atoi converts string to integer
    int num_parts = atoi(argv[2]);        // Convert 2nd argument to integer
    int part_to_reverse = atoi(argv[3]);  // Convert 3rd argument to integer

    // Validate input arguments
    if (num_parts <= 0 || part_to_reverse <= 0 || part_to_reverse > num_parts) {
        fprintf(stderr, "Invalid number of parts\n");
        exit(EXIT_FAILURE);
    }

    const char *dir_name = "Assignment";

    // Extract only the file name from input path
    const char *input_file_name = strrchr(input_file_path, '\\');
    if (input_file_name)
        input_file_name++; // Skip the '/'
    else
        input_file_name = input_file_path;
//with user read/write/execute permissions (0700)
   // if (mkdir(dir_name, 0700) == -1)
      if(mkdir(dir_name)==-1)
    {
        if (errno != EEXIST) {
            perror("mkdir failed");
            exit(EXIT_FAILURE);
        }
    }

    // Create the output file path: Assignment/2_<filename>
    char output_file_path[1024];
    sprintf(output_file_path, "%s/2_%s", dir_name, input_file_name);

    // Open input file for reading
    int input_fd = open(input_file_path, O_RDONLY);
    if (input_fd == -1) {
        perror("open input");
    
        exit(EXIT_FAILURE); 
    }

    // Open output file for writing with 0600 permissions
    int output_fd = open(output_file_path, _O_WRONLY | _O_CREAT | _O_TRUNC|_S_IREAD|_S_IWRITE);
    if (output_fd == -1) {
        perror("open output");
        close(input_fd);
        exit(EXIT_FAILURE);
    }

    // Find file size using lseek
    off_t file_size = lseek(input_fd, 0, SEEK_END);
    if (file_size == -1) {
        perror("lseek");
        close(input_fd);
        close(output_fd);
        exit(EXIT_FAILURE);
    }

    // Calculate size of each part
    off_t part_size = file_size / num_parts;

    /* Calculate offset of the part to reverse
	ex:helloworld  - file size: 10 bytes if no of parts is 2 and the part to reverse is 2
        part_size=10/2=5
        then  p1:hello p2:world  so reverse 2nd part:dlrow
        start_offset=5*(2-1)=5*1=5
        end_offset=5+5=10
    */

    off_t start_offset = part_size * (part_to_reverse - 1);
    off_t end_offset = start_offset + part_size;

    // keep track of bytes written
    off_t total_written = 0;
    
    // to store the data in temparory storage 
    char buffer[CHUNK_SIZE];

    // to reverse only that part
    off_t remaining = part_size;

    while (remaining > 0) {
	/*   ex: if part_size=10000 then
             iteration1:
             remaining=10000

             start_offset=10000*(3-1)=20000  end_offset=20000+8192=28192
             to_read=8192  offset=20000-8192=11808   read bytes from 11808 to 19999  
             reverse this buffer and write 8192 bytes to output file  
             remaining=10000-8192=1808 and total_written=8192 end_offset=offset=11808
	     iteration2:
             remaining=1808 >0   to_read=1808 offset=11808-1808=10000
             read 1808 bytes from 10000 to 11807
             reverse this buffer and write 1808 reversed bytes to output file
             total_written=8192+1808=10000
             remaining=1808-1808=0 loop ends
        */
        size_t to_read = (remaining >= CHUNK_SIZE) ? CHUNK_SIZE : remaining;
        off_t offset = end_offset-to_read;
        // Move file pointer to the calculated offset
        if (lseek(input_fd, offset, SEEK_SET) == -1) {
            perror("lseek chunk");
            break;
        }

        // Read the chunk
        ssize_t bytes_read = read(input_fd, buffer, to_read);
        if (bytes_read <= 0) {
            perror("read");
            break;
        }

        // Reverse the chunk
        for (ssize_t i = 0; i < bytes_read / 2; i++) {
            char temp = buffer[i];
            buffer[i] = buffer[bytes_read - i - 1];
            buffer[bytes_read - i - 1] = temp;
        }

        // Write the reversed chunk to output
        ssize_t bytes_written = write(output_fd, buffer, bytes_read);
        if (bytes_written != bytes_read) {
            perror("write");
            break;
        }

        total_written += bytes_written;
        remaining -= to_read;
        end_offset=offset;//update the endoffset for next chunk

        // Printing progress
        double percent = (total_written * 100.0) / part_size;
        char percentBuffer[100];
        sprintf(percentBuffer, "\rProgress: %.2f%%", percent);
        write(1, percentBuffer, strlen(percentBuffer));
        fflush(stdout);
    }

    //close the input and output files
    close(input_fd);
    close(output_fd);
    return 0;
}